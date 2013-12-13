module QBIntegration
  module Service
    # Both Spree line items and adjustments are mapped as SalesReceipt lines
    class Line < Base
      attr_reader :line_items, :adjustments, :lines, :config

      def initialize(config, payload)
        @config = config
        @model_name = "Line"
        @line_items = payload[:order][:line_items]
        @adjustments = payload[:original][:adjustments]
        @lines = []
      end

      def build_lines
        build_from_line_items
        build_from_adjustments

        lines
      end

      def build_from_line_items
        line_items.each do |line_item|
          line = create_model

          sku = line_item["sku"]
          description = line_item["name"]
          price = line_item["price"]
          quantity = line_item["quantity"]

          line.amount = (quantity * price)
          line.description = description

          line.sales_item! do |sales_item|
            sales_item.item_ref = 1 # create_item(sku, description, price).id
            sales_item.quantity = line_item["quantity"]
            sales_item.unit_price = line_item["price"]
          end

          lines.push line
        end
      end

      def build_from_adjustments
        eligible_adjustments.each do |adjustment|
          line = create_model

          sku = map_adjustment_sku(adjustment)

          line.amount = adjustment["amount"]
          line.description = adjustment["label"]

          line.sales_item! do |sales_item|
            # sales_item.item_ref = 1 # create_item(sku, description, price).id
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
          if adjustments[:amount].to_f < 0
            config.fetch("quickbooks.discount_item")
          elsif adjustments[:amount].to_f > 0
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
