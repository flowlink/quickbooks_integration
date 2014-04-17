module QBIntegration
  class Product < Base
    attr_reader :product_payload

    def initialize(message = {}, config)
      super

      @product_payload = @product = @payload[:product]
    end

    def import
      load_configs
      import_product(@product)
      @product.fetch(:variants, []).collect {|variant| import_product(variant)}

      [200, @notification]
    end

    private
    def load_configs
      @income_account_id = account_id('quickbooks_income_account')

      if @inventory_costing = (@config.fetch("quickbooks_track_inventory", false).to_s == 'true')
        @inventory_account_id = account_id('quickbooks_inventory_account')
        @cogs_account_id = account_id('quickbooks_cogs_account')
      end
    end

    def account_id(account_name)
      account_service.find_by_name(@config.fetch(account_name)).id
    end

    def attributes(product)
      attrs = {
        name: product[:sku],
        description: product[:description],
        unit_price: product[:price],
        purchase_cost: product[:cost_price],
        income_account_id: @income_account_id,
        type: 'Non Inventory'
      }

      # Test accounts do not support track_inventory feature
      if config.fetch("quickbooks_track_inventory", false).to_s == "true"
        attrs.merge!({
          track_quantity_on_hand: true,
          quantity_on_hand: 1,
          inv_start_date: time_now
        })
      end

      if import_as_sub_item?(product)
        attrs[:sub_item] = true
        attrs[:parent_ref] = parent_ref
      end

      if @inventory_costing
        attrs[:type] = 'Inventory'
        attrs[:asset_account_id] = @inventory_account_id
        attrs[:expense_account_id] = @cogs_account_id
      end

      attrs
    end

    def import_as_sub_item?(product)
      product[:sku] != @product[:sku]
    end

    def import_product(product)
      if item = item_service.find_by_sku(product[:sku])
        item_service.update(item, attributes(product))
        add_notification('update', product)
      else
        item_service.create(attributes(product))
        add_notification('create', product)
      end
    end

    def parent_ref
      @parent_ref ||= item_service.find_by_sku(@product[:sku]).id
    end

    def add_notification(operation, product)
      @notification = text[operation] % product[:sku]
    end

    def text
      @text ||= {
        'create' => "Product %s imported to Quickbooks.",
        'update' => "Product %s updated on Quickbooks."
      }
    end

    def time_now
      Time.now.utc
    end
  end
end
