module QBIntegration
  module Service
    # Both Spree line items and adjustments are mapped as SalesReceipt lines
    #
    # Return authorizations inventory units variants are alsy sync as Credit
    # Memo lines
    class Line < Base
      attr_reader :line_items, :adjustments, :lines, :config, :item_service,
        :inventory_units, :return_authorization, :order

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
      end

      def build_lines(account = nil)
        build_from_line_items account
        build_from_adjustments account

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
          lines.push built_line
        end
        lines
      end

      def build_from_line_items(account = nil)
        line_items.each do |line_item|
          line = create_model

          price = line_item["price"]
          quantity = line_item["quantity"]

          line.amount = (quantity * price)
          line.description = line_item["name"]

          line.sales_item! do |sales_item|
            unless item_found = item_service.find_or_create_by_sku(line_item, account)
              sku = line_item[:product_id] if line_item[:sku].to_s.empty?
              sku = line_item[:sku] if sku.to_s.empty?
              raise RecordNotFound.new "Quickbooks record not found for product: #{sku}"
            end
            sales_item.item_id = item_found.id
            sales_item.quantity = line_item["quantity"]
            sales_item.unit_price = line_item["price"]

            sales_item.tax_code_id = line_item["tax_code_id"] if line_item["tax_code_id"]
          end

          lines.push line
        end
      end

      def build_from_adjustments(account = nil)
        adjustments.each do |adjustment|

          # Get sku of adjustment, and move on if empty
          sku = QBIntegration::Helper.adjustment_product_from_qb adjustment[:name], @config
          puts 'Sku is: ' + sku.to_s
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

          lines.push line
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

          lines.push line
        end

        lines
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


    end
  end
end
