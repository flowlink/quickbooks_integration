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
        @adjustments = payload[:original][:adjustments]
        @return_authorization = payload[:return_authorization] || {}
        @inventory_units = return_authorization[:inventory_units] || []

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

      # NOTE watch out as the price here might not always be accurate. If the
      # variant price changed after the order was created we'd get that price
      # here not the one in the order line item
      #
      # TODO We should group inventory units variant and create only one line
      # per variant with the proper quantity set
      def build_from_inventory_units(account = nil)
        inventory_units.each do |unit|
          line = create_model

          line.amount = unit[:variant][:price]
          line.description = unit[:variant][:name]

          line.sales_item! do |sales_item|
            sales_item.item_ref = item_service.find_or_create_by_sku(unit[:variant], account).id
            sales_item.quantity = 1
            sales_item.unit_price = unit[:variant][:price]
          end

          lines.push line
        end

        lines
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
