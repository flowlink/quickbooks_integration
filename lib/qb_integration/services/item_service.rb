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
    end
  end
end
