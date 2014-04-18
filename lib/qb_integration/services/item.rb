module QBIntegration
  module Service
    class Item < Base
      def initialize(config)
        super("Item", config)
      end

      def find_by_sku(sku, fields = "*")
        response = @quickbooks.query("select #{fields} from Item where Name = '#{sku}'")
        response.entries.first
      end

      def find_by_updated_at
        filter = "Where Metadata.LastUpdatedTime > '#{config.fetch("quickbooks_poll_stock_timestamp")}'"
        response = @quickbooks.query "select Name, QtyOnHand from Item #{filter} Order By Metadata.LastUpdatedTime"
        response.entries
      end

      # NOTE what if a product is given?
      def find_or_create_by_sku(line_item, account = nil)
        name = line_item[:sku] || line_item[:product_id]

        params = {
          name: name,
          description: line_item[:description],
          unit_price: line_item[:price],
          purchase_cost: line_item[:cost_price],
          income_account_id: account ? account.id : nil
        }

        find_by_sku(name) || create(params)
      end
    end
  end
end
