module QBIntegration
  module Service
    class Item < Base
      def initialize(config)
        super("Item", config)
      end

      def find_by_sku(sku)
        response = @quickbooks.query("select * from Item where Name = '#{sku}'")
        response.entries.first
      end

      # NOTE what if a product is given?
      def find_or_create_by_sku(line_item, account = nil)
        params = {
          name: line_item[:sku],
          description: line_item[:description],
          unit_price: line_item[:price],
          purchase_cost: line_item[:cost_price],
          income_account_id: account ? account.id : nil
        }

        find_by_sku(line_item[:sku]) || create(params)
      end
    end
  end
end
