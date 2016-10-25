module QBIntegration
  module Service
    class Item < Base
      def initialize(config)
        super("Item", config)
      end

      def find_by_name(sku, fields = "*")
        response = quickbooks.query("select #{fields} from Item where Name = '#{sku}'")
        response.entries.first
      end

      def find_by_sku(sku, fields = "*")
        response = quickbooks.query("select #{fields} from Item where Sku = '#{sku}'")
        response.entries.first
      end

      def find_by_updated_at
        raise MissingTimestampParam unless config["quickbooks_poll_stock_timestamp"].present?

        filter = "Where Metadata.LastUpdatedTime > '#{config.fetch("quickbooks_poll_stock_timestamp")}'"
        order = "Order By Metadata.LastUpdatedTime"
        response = quickbooks.query "select Name, QtyOnHand, Metadata.LastUpdatedTime from Item #{filter} #{order}"

        response.entries
      end

      # NOTE what if a product is given?
      def find_or_create_by_sku(line_item, account = nil)
        name = line_item[:sku] || line_item[:product_id]

        quickbooks_track_inventory = config.fetch("quickbooks_track_inventory", false).to_s
        track_inventory = quickbooks_track_inventory == "true" || quickbooks_track_inventory == "1"
        if track_inventory
          type = Quickbooks::Model::Item::INVENTORY_TYPE
        else
          type = Quickbooks::Model::Item::NON_INVENTORY_TYPE
        end

        params = {
          name: name,
          description: line_item[:description],
          unit_price: line_item[:price],
          purchase_cost: line_item[:cost_price],
          income_account_id: account ? account.id : nil,
          type: type
        }

        find_by_sku(name) || find_by_name(name) || create(params)
      end
    end
  end
end
