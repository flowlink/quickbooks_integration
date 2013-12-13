module QBIntegration
  module Service
    # Both Spree line items and adjustments are mapped as SalesReceipt lines
    class Line < Base
      attr_reader :line_items, :adjustments, :lines, :config, :item_service

      def initialize(config, payload)
        @config = config
        @model_name = "Line"
        @line_items = payload[:order][:line_items]
        @adjustments = payload[:original][:adjustments]

        @lines = []
        @item_service = Item.new(config)
      end

      def build_lines(account = nil)
        build_from_line_items account
        build_from_adjustments account

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
            sales_item.item_ref = item_service.find_or_create_by_sku(line_item, account).id
            sales_item.quantity = line_item["quantity"]
            sales_item.unit_price = line_item["price"]
          end

          lines.push line
        end
      end

      def build_from_adjustments(account = nil)
        eligible_adjustments.each do |adjustment|
          line = create_model

          sku = map_adjustment_sku(adjustment)

          line.amount = adjustment["amount"]
          line.description = adjustment["label"]

          # make an adjustment look like a line_item
          adjustment[:price] = adjustment["amount"]
          adjustment[:name] = adjustment["label"]
          adjustment[:sku] = sku

          line.sales_item! do |sales_item|
            sales_item.item_ref = item_service.find_or_create_by_sku(adjustment, account).id
            sales_item.quantity = 1
            sales_item.unit_price = adjustment["amount"]
          end

          lines.push line
        end
      end

      # NOTE Watch out for Spree >= 2.2
      def map_adjustment_sku(adjustment)
        case adjustment[:originator_type]
        when "Spree::ShippingMethod"
          config.fetch("quickbooks.shipping_item")
        when "Spree::TaxRate"
          config.fetch("quickbooks.tax_item")
        when "Spree::PromotionAction"
          config.fetch("quickbooks.discount_item")
        when nil
          if adjustment[:amount].to_f < 0.0
            config.fetch("quickbooks.discount_item")
          elsif adjustment[:amount].to_f > 0.0
            "Manual Charge"
          end
        else
          "Manual Charge"
        end
      end

      def eligible_adjustments
        adjustments.select { |a| a["eligible"] }
      end
    end
  end
end
