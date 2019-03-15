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
        unless sku
          raise NoSkuForOrderException.new('Error: SKU cannot be empty')
        end
        clause1 = util.clause('Sku', '=', sku)
        response = quickbooks.query("select #{fields} from Item where #{clause1}")
        response.entries.first
      end

      def find_by_updated_at(page_num = nil)
        raise MissingTimestampParam unless config["quickbooks_poll_stock_timestamp"].present?

        filter = "Where Metadata.LastUpdatedTime > '#{config.fetch("quickbooks_poll_stock_timestamp")}'"
        order = "Order By Metadata.LastUpdatedTime"
        query = "select * from Item #{filter} #{order}"
        
        if page_num
          response = quickbooks.query(query, :page => page_num, :per_page => PER_PAGE_AMOUNT)
          new_page = response.count == PER_PAGE_AMOUNT ? page_num.to_i + 1 : 1
          [response.entries, new_page]
        else
          response = quickbooks.query(query)
          response.entries
        end        
      end

      # NOTE what if a product is given?
      def find_or_create_by_sku(line_item, account = nil)
        name = line_item[:sku] if line_item[:sku].to_s.empty?
        name = line_item[:product_id] if name.to_s.empty?
        name = line_item[:name] if name.to_s.empty?

        sku = line_item[:product_id] if line_item[:sku].to_s.empty?
        sku = line_item[:sku] if sku.to_s.empty?

        quickbooks_track_inventory = config.fetch("quickbooks_track_inventory", false).to_s
        track_inventory = quickbooks_track_inventory == "true" || quickbooks_track_inventory == "1"
        if track_inventory
          type = Quickbooks::Model::Item::INVENTORY_TYPE
        else
          type = Quickbooks::Model::Item::NON_INVENTORY_TYPE
        end

        params = {
          name: name,
          sku: sku,
          description: line_item[:description],
          unit_price: line_item[:price],
          purchase_cost: line_item[:cost_price],
          income_account_id: account ? account.id : nil,
          type: type
        }
        find_by_sku(sku) || find_by_name(name) || create_new_product(params)
      end

      def create_new_product(params)
        create = config.fetch("quickbooks_create_new_product")
        return unless create && create.to_s == "1"
        create(params)
      end
    end
  end
end
