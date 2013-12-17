module QBIntegration
  class ProductImporter < Base
    def initialize(message = {}, config)
      super

      @product = @payload[:product]
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

    private
    def load_configs
      @variants_as_sub_items = (@config.fetch("quickbooks.variants_as_sub_items").to_s == 'true')
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
      @variants_as_sub_items && (product[:sku] != @product[:sku])
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

      @text['create'][true]  = "Imported product with Sku = #{sku} as sub-item of product with Sku = #{@product[:sku]} to Quickbooks successfully."
      @text['create'][false] = "Imported product with Sku = #{sku} to Quickbooks successfully."

      @text['update'][true]  = "Updated product with Sku = #{sku} on Quickbooks successfully."
      @text['update'][false] = "Updated product with Sku = #{sku} on Quickbooks successfully."

      @notifications << @text[operation][import_as_sub_item?(product)]
    end
  end
end
