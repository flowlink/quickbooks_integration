module QBIntegration
  module Service
    class InvoiceLine < Base
      attr_reader :line_items, :lines, :config, :item_service, :adjustments

      def initialize(config, payload)
        @config = config
        @model_name = "InvoiceLineItem"
        @line_items = payload[:invoice][:line_items] || []
        @adjustments = payload[:invoice][:adjustments] || []
        @lines = []
        @item_service = Item.new(config)
      end

      def build_lines(account = nil)
        build_from_line_items(account)
        build_from_adjustments(account)

        lines
      end

      def build_from_line_items(account = nil)
        line_items.each do |line_item|
          line = create_model
          
          unless item_found = item_service.find_or_create_by_sku(line_item, account)
            sku = line_item[:product_id] if line_item[:sku].to_s.empty?
            sku = line_item[:sku] if sku.to_s.empty?
            raise RecordNotFound.new "QuickBooks record not found for product: #{sku}"
          end
          
          if item_found.type == "Group"
            line.group_line_detail! do |detail|
              detail.id = item_found.id
              detail.group_item_ref = Quickbooks::Model::BaseReference.new(item_found.name, value: item_found.id)
              detail.quantity = line_item["quantity"]
          
              item_found.item_group_details.line_items.each do |group_line|
                g_line_item = create_model
                group_item_found = item_service.find_by_id(group_line.id)

                g_line_item.amount = group_line.quantity.to_i * group_item_found.unit_price.to_f

                g_line_item.sales_item! do |gl|
                  gl.item_id = group_line.id
                  gl.quantity = group_line.quantity.to_i
                  gl.unit_price = group_item_found.unit_price.to_f
                end
          
                detail.line_items << g_line_item
              end
            end
          else      
            price = line_item["price"]
            quantity = line_item["quantity"]

            unless price && quantity
              raise UnsupportedException.new "Line Items must have a valid price and quantity"
            end

            line.amount = quantity * price
            line.description = line_item["name"]

            line.sales_item! do |sales_item|
              sales_item.item_id = item_found.id
              sales_item.quantity = quantity
              sales_item.unit_price = price
              # TODO: we should be querying QBO to ensure this actually exists. Raise an error if it doesn't?
              sales_item.tax_code_id = line_item["tax_code_id"] if line_item["tax_code_id"]
              sales_item.rate_percent = line_item["rate"] if line_item["rate"]
              # TODO: Add Class ref, Price Level ref, Service Date
            end
          end

          lines.push line
        end
      end

      def build_from_adjustments(account = nil)
        adjustments.each do |adjustment|

          # Get sku of adjustment, and move on if empty
          sku = QBIntegration::Helper.adjustment_product_from_qb(adjustment[:name], @config, {})
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
          adjustment[:sku] = sku

          line.sales_item! do |sales_item|
            sales_item.item_id = item_service.find_or_create_by_sku(adjustment, account).id
            sales_item.quantity = 1
            sales_item.unit_price = adjustment["value"].to_f * multiplier

            # TODO: we should be querying QBO to ensure this actually exists. Raise an error if it doesn't?
            sales_item.tax_code_id = adjustment["tax_code_id"] if adjustment["tax_code_id"]
            sales_item.rate_percent = adjustment["rate"] if adjustment["rate"]

            # TODO: Add Class ref, Price Level ref, Service Date
          end

          lines.push line
        end
      end
    end
  end
end
