module QBIntegration
  module Service
    # Both Spree line items and adjustments are mapped as SalesReceipt lines
    #
    # Return authorizations inventory units variants are alsy sync as Credit
    # Memo lines
    class Line < Base
      attr_reader :line_items, :adjustments, :lines, :config, :item_service,
        :inventory_units, :return_authorization, :order, :account_service

      def initialize(config, payload)
        @config = config
        @model_name = "Line"
        @order = payload[:order] || {}
        @line_items = order[:line_items] || []
        if !payload[:order].nil?
          @adjustments = payload[:order][:adjustments] || []
        else
          @adjustments = []
        end
        @return_authorization = payload[:return] || payload[:refund] || {}
        @inventory_units = return_authorization[:refund_line_items] || []

        @lines = []
        @item_service = Item.new(config)
        @account_service = Account.new(config)
      end

      def build_lines(account = nil)
        build_from_line_items(account)
        build_from_adjustments(account)

        lines
      end

      def build_purchase_order_lines(account, purchase_order)
        @line_items = purchase_order["line_items"]
        line_items.each do |line_item|
          if line_item["quantity"]
            built_line = build_item_based_expense(line_item, account, purchase_order)
          else
            built_line = build_account_based_expense(line_item, account, purchase_order)
          end
          lines.push(built_line)
        end
        lines
      end

      def build_payment_lines(flowlink_payment, parent)
        line = create_model
        # Right now we only have single payments at once. We'll need to update this to handle multiple payments
        line.amount = flowlink_payment[:amount]
        line.linked_transactions = LinkedTransaction.new([parent]).build
        lines.push line

        lines
      end

      def build_from_line_items(account = nil)
        line_items.each do |line_item|
          line = create_model

          unless item_found = item_service.find_or_create_by_sku(line_item, account, order)
            sku = line_item[:product_id] if line_item[:sku].to_s.empty?
            sku = line_item[:sku] if sku.to_s.empty?
            raise RecordNotFound.new "QuickBooks record not found for product: #{sku}"
          end

          if item_found.type == "Group"
            # Currently, the ruckus QuickBooks gem we use doesn't allow for adding bundles to sales receipts
            raise UnsupportedException.new "Bundled Item Present: FlowLink does not support adding bundled items to Sales Receipts at this time. Please contatct a FlowLink representative for more information."
            
            # line.group_line_detail! do |detail|
            #   detail.id = item_found.id
            #   detail.group_item_ref = Quickbooks::Model::BaseReference.new(item_found.name, value: item_found.id)
            #   detail.quantity = line_item["quantity"]
          
            #   item_found.item_group_details.line_items.each do |group_line|
            #     g_line_item = create_model
            #     group_item_found = item_service.find_by_id(group_line.id)

            #     g_line_item.amount = group_line.quantity.to_i * group_item_found.unit_price.to_f

            #     g_line_item.sales_item! do |gl|
            #       gl.item_id = group_line.id
            #       gl.quantity = group_line.quantity.to_i
            #       gl.unit_price = group_item_found.unit_price.to_f
            #     end
          
            #     detail.line_items << g_line_item
            #   end
            # end
          else
            unless line_item["price"] && line_item["quantity"]
              raise UnsupportedException.new "Line Items must have a valid price and quantity"
            end
            line.amount = (line_item["quantity"].to_i * line_item["price"].to_f)
            line.description = line_item["name"]

            line.sales_item! do |sales_item|
              sales_item.item_id = item_found.id
              sales_item.quantity = line_item["quantity"].to_i
              sales_item.unit_price = line_item["price"].to_f
              # TODO: we should be querying QBO to ensure this actually exists. Raise an error if it doesn't?
              sales_item.tax_code_id = line_item["tax_code_id"] if line_item["tax_code_id"]
               # TODO: Add Class ref, Price Level ref, Service Date
            end
          end

          lines.push(line)
        end
      end

      def build_from_adjustments(account = nil)
        adjustments.each do |adjustment|

          # Get sku of adjustment, and move on if empty
          sku = QBIntegration::Helper.adjustment_product_from_qb(adjustment[:name], @config, order)
          if sku.to_s.empty?
            next
          end

          line = create_model

          # Discounts will be counted as negative
          multiplier = (adjustment['name'] == 'Discounts') ? -1 : 1

          line.amount = adjustment["value"].to_f * multiplier
          line.description = adjustment["name"]

          # make an adjustment look like a line_item
          adjustment[:price] = adjustment["value"].to_f * multiplier
          adjustment[:name] = adjustment["name"]
          adjustment[:sku] = adjustment['name'].downcase == "tax" ? "" : sku
          puts 'Sku now is: ' + adjustment[:sku].to_s

          line.sales_item! do |sales_item|
            sales_item.item_id = item_service.find_or_create_by_sku(adjustment, account).id
            sales_item.quantity = 1
            sales_item.unit_price = adjustment["value"].to_f * multiplier

            sales_item.tax_code_id = adjustment["tax_code_id"] if adjustment["tax_code_id"]
          end

          lines.push(line)
        end
      end

      # NOTE watch out as the price here might not always be accurate. If the
      # variant price changed after the order was created we'd get that price
      # here not the one in the order line item
      #
      # TODO We should group inventory units variant and create only one line
      # per variant with the proper quantity set
      def build_from_inventory_units(account = nil)
        inventory_units.each do |unit|
          line = create_model

          line.amount = unit[:subtotal]
          line.description = unit[:name]

          line.sales_item! do |sales_item|
            sales_item.item_id = item_service.find_or_create_by_sku(unit, account).id
            sales_item.quantity = unit[:quantity]
            sales_item.unit_price = unit[:subtotal].to_f / unit[:quantity]
          end

          lines.push(line)
        end

        lines
      end

      def build_item_based_lines(po_model, po_payload)
        line = Quickbooks::Model::BillLineItem.new
        line.item_based_expense_item!

        # TODO: Update this to match by the line_item_name in quantity_received_in_qbo
        item_detail = po_model.line_items.first.item_based_expense_line_detail
        unit_price = item_detail["unit_price"]

        # TODO: Update to use quantity_received_in_qbo
        line.amount = po_payload["quantity_received"].to_i * unit_price

        line.item_based_expense_line_detail = item_detail
        [ line ]
      end

      private

      def build_item_based_expense(line_item, account, purchase_order)
          line = Quickbooks::Model::PurchaseLineItem.new
          price = line_item["price"]
          quantity = line_item["quantity"]

          line.amount = (quantity * price)
          line.description = line_item["name"]

          line.item_based_expense! do |detail|
            unless item_found = item_service.find_or_create_by_sku(line_item, account)
              sku = line_item[:product_id] if line_item[:sku].to_s.empty?
              sku = line_item[:sku] if sku.to_s.empty?
              raise RecordNotFound.new "Quickbooks record not found for item: #{sku}"
            end
            detail.item_id = item_found.id
            detail.quantity = line_item["quantity"]
            detail.unit_price = line_item["price"]
            detail.tax_code_id = line_item["tax_code_id"] if line_item["tax_code_id"]
          end
          line
      end

      def build_account_based_expense(line_item, account, purchase_order)
          line = Quickbooks::Model::PurchaseLineItem.new
          price = line_item["price"]
          line.description = line_item["name"]

          line.account_based_expense! do |detail|
            unless account_found = account_service.find_by_name(line_item["name"])
              raise RecordNotFound.new "Quickbooks record not found for account: #{line_item["name"]}"
            end
            detail.account_id = account_found.id
          end
          line
      end

    end
  end
end
