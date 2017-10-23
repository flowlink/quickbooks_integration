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
        util = Quickbooks::Util::QueryBuilder.new
        clause1 = util.clause('Sku', '=', sku)
        response = quickbooks.query("select #{fields} from Item where #{clause1}")
        response.entries.first
      end

      def find_by_updated_at
        raise MissingTimestampParam unless config["quickbooks_poll_stock_timestamp"].present?

        filter = "Where Metadata.LastUpdatedTime > '#{config.fetch("quickbooks_poll_stock_timestamp")}'"
        order = "Order By Metadata.LastUpdatedTime"
        response = quickbooks.query "select * from Item #{filter} #{order}"

        response.entries
      end

      # NOTE what if a product is given?
      def find_or_create_by_sku(line_item, account = nil)
        name = line_item[:sku] if line_item[:sku].to_s.empty?
        name = line_item[:product_id] if name.to_s.empty?
        name = line_item[:name] if name.to_s.empty?

        sku = line_item[:product_id] if line_item[:sku].to_s.empty?
        sku = line_item[:sku] if sku.to_s.empty?

        params = {
          name: name,
          sku: sku,
          description: line_item[:description],
          unit_price: line_item[:price],
          purchase_cost: line_item[:cost_price],
          income_account_id: account ? account.id : nil
        }

        find_by_sku(sku) || find_by_name(name) || create(params)
      end
    end
  end
end
