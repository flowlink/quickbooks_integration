module QBIntegration
  class ProductImporter < Base
    def initialize(message = {}, config)
      super

      @product = @payload[:product]
      @notifications = []
    end

    def import
      load_configs

      import_product(@product)

      @product.fetch(:variants, []).collect {|variant| import_product(variant)}

      [200, notifications]

    rescue => e
      [500, {
        'message_id' => @message_id,
        'notifications' => [{
          'level' => 'error',
          'subject' => e.message,
          'description' => e.backtrace.join('\n')
        }]
      }]
    end

    private
    def load_configs
      @income_account_id = account_id('quickbooks.income_account')

      if @inventory_costing = (@config.fetch("quickbooks.inventory_costing").to_s == 'true')
        @inventory_account_id = account_id('quickbooks.inventory_account')
        @cogs_account_id = account_id('quickbooks.cogs_account')
      end
    end

    def account_id(account_name)
      account_service.find_by_name(@config.fetch(account_name)).id
    end

    def attributes(product)
      @attributes = {
        name: product[:sku],
        description: product[:description],
        unit_price: product[:price],
        purchase_cost: product[:cost_price],
        income_account_ref: @income_account_id,
        type: 'Non Inventory'
      }

      if import_as_sub_item?(product)
        @attributes[:sub_item] = true
        @attributes[:parent_ref] = parent_ref
      end

      if @inventory_costing
        @attributes[:type] = 'Inventory'
        @attributes[:asset_account_ref] = @inventory_account_id
        @attributes[:expense_account_ref] = @cogs_account_id
      end

      @attributes
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

    def notifications
      notifications_json = @notifications.map do |text|
        {
          'level' => 'info',
          'subject' => text,
          'description' => text
        }
      end

      {
        'message_id' => @message_id,
        'notifications' => notifications_json
      }
    end

    def add_notification(operation, product)
      @notifications.push(text[operation] % product[:sku])
    end

    def text
      @text ||= {
        'create' => "Product %s imported to Quickbooks.",
        'update' => "Product %s updated on Quickbooks."
      }
    end
  end
end
