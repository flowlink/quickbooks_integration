module QBIntegration
  class ProductImporter < Base
    def initialize(message = {}, config)
      super

      @product = @payload[:product]
    end

    def load_configs
      @variants_as_sub_items = (@config.fetch("quickbooks.variants_as_sub_items").to_s == 'true')
      @income_account = @config.fetch("quickbooks.income_account")

      if @inventory_costing = (@config.fetch("quickbooks.inventory_costing").to_s == 'true')
        @inventory_account = @config.fetch('quickbooks.inventory_account')
        @cogs_account = @config.fetch('quickbooks.cogs_account')
      end
    end

    def import
      load_configs

      import_product(@product)

      @product.fetch(:variants, []).collect {|variant| import_product(variant)}

      [200, notifications]

    rescue Exception => e
      [200, {
        'message_id' => @message_id,
        'notifications' => [{
          'level' => 'error',
          'subject' => e.message,
          'description' => e.backtrace.join('\n')
        }]
      }]
    end

    def attributes(product)
      income_account_id = account_service.find_by_name(@income_account).id

      @attributes = {
        name: product[:sku],
        description: product[:description],
        unit_price: product[:price],
        income_account_ref: income_account_id,
        sub_item: false,
        type: 'Non Inventory'
      }

      if @variants_as_sub_items && !product.key?(:variants)
        @attributes[:sub_item] = true
        @attributes[:parent_ref] = parent_ref
      end

      if @inventory_costing
        @attributes[:type] = 'Inventory'
        @attributes[:asset_account_ref] = account_service.find_by_name(@inventory_account).id
        @attributes[:expense_account_ref] = account_service.find_by_name(@cogs_account).id
      end

      @attributes
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
      @notifications ||= []
      @text ||= {
        'create' => {},
        'update' => {}
      }

      sku = product[:sku]

      imported_as_sub_item = @variants_as_sub_items && !product.key?(:variants)

      @text['create'][true]  = "Imported product with Sku = #{sku} as sub-item of product with Sku = #{@product[:sku]} to Quickbooks successfully."
      @text['create'][false] = "Imported product with Sku = #{sku} to Quickbooks successfully."

      @text['update'][true]  = "Updated product with Sku = #{sku} on Quickbooks successfully."
      @text['update'][false] = "Updated product with Sku = #{sku} on Quickbooks successfully."

      @notifications << @text[operation][imported_as_sub_item]
    end
  end
end
