module QBIntegration
  module Service
    class Item < Base
      def initialize(config)
        super("Item", config)
      end

      def find_by_id(id, fields = "*")
        response = quickbooks.query("select #{fields} from Item where Id = '#{id}'")
        response.entries.first
      end

      def find_by_name(sku, fields = "*")
        response = quickbooks.query("select #{fields} from Item where Name = '#{sku}'")
        response.entries.first
      end

      def find_category_by_name(name, fields = "*")
        response = quickbooks.query("select #{fields} from Item where Name = '#{name}' and Type='Category'")
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
      def find_or_create_by_sku(line_item, account = nil, payload_object = {})
        name = line_item[:sku] if line_item[:sku].to_s.empty?
        name = line_item[:product_id] if name.to_s.empty?
        name = line_item[:name] if name.to_s.empty?

        sku = line_item[:product_id] if line_item[:sku].to_s.empty?
        sku = line_item[:sku] if sku.to_s.empty?

        find_by_sku(sku) || find_by_name(name) || create_new_product(line_item, sku, name, account, payload_object)
      end

      def create_new_product(line_item, sku, name, account, payload_object)
        create = find_value("quickbooks_create_new_product", payload_object, config)
        return unless create && create.to_s == "1"

        account_service = Account.new config
        params = {
          name: name,
          sku: sku,
          description: line_item[:description],
          unit_price: line_item[:price],
          purchase_cost: line_item[:cost_price],
          income_account_id: account ? account.id : nil
        }

        quickbooks_track_inventory = find_value("quickbooks_track_inventory", payload_object, config)

        track_inventory = quickbooks_track_inventory == "true" || quickbooks_track_inventory == "1"
        if track_inventory
          unless check_account("quickbooks_inventory_account", payload_object, config) && check_account("quickbooks_cogs_account", payload_object, config)
            raise RecordNotFound.new "Workflow parameter missing for Inventory items: quickbooks_inventory_account or quickbooks_cogs_account"            
          end

          params[:quantity_on_hand] = line_item[:quantity] ? line_item[:quantity] : 0

          params[:track_quantity_on_hand] = true
          params[:inv_start_date] = time_now

          inventory_name = decide_name("quickbooks_inventory_account", payload_object, config)
          cogs_name = decide_name("quickbooks_cogs_account", payload_object, config)

          params[:asset_account_id] = account_service.find_by_name(inventory_name).id
          params[:expense_account_id] = account_service.find_by_name(cogs_name).id
          params[:type] = Quickbooks::Model::Item::INVENTORY_TYPE
        else
          params[:type] = Quickbooks::Model::Item::NON_INVENTORY_TYPE
        end

        if line_item[:quickbooks_income_account]
          params[:income_account_id] = account_service.find_by_name(line_item[:quickbooks_income_account]).id
        end

        if line_item[:quickbooks_expense_account]
          params[:expense_account_id] = account_service.find_by_name(line_item[:quickbooks_expense_account]).id
        end

        create(params)
      end

      def time_now
        Time.now.utc
      end

      private

      def check_account(key_name, payload_object, parameters)
        payload_object[key_name].present? || parameters[key_name].present?
      end

      def decide_name(key_name, payload_object, parameters)
        payload_object.fetch(key_name, parameters[key_name])
      end

      def find_value(key_name, payload_object, parameters)
        payload_object.fetch(key_name,  parameters.fetch(key_name, false)).to_s
      end

    end
  end
end
