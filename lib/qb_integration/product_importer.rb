module QBIntegration
  class ProductImporter < Base
    def initialize(message = {}, config)
      super

      @product = @payload[:product]
    end

    def import
      import_product(@product)

      @product[:variants].collect {|variant| import_variant(variant)}

      [200, notifications]

    rescue KeyError => e
      [200, {
        'message_id' => @message_id,
        'notifications' => [{
          'level' => 'error',
          'subject' => e.message,
          'description' => e.message
        }]
      }]
    end

    def import_variant(variant)
      import_as_sub_item = @config.fetch("quickbooks.import_as_sub_item")

      import_product(variant, import_as_sub_item)
    end

    def import_product(product, import_as_sub_item = false)
      sku, description, price = product[:sku], product[:description], product[:price]

      if item = item_service.find_by_sku(sku)
        attributes = { description: description, unit_price: price }
        attributes.merge!({ sub_item: true, parent_ref: parent_ref }) if import_as_sub_item

        item_service.update(item, attributes)

        add_notification('update', product, import_as_sub_item)
      else
        account = account_service.find_by_name @config.fetch("quickbooks.account_name")

        attributes = {
          name: sku,
          description: description,
          unit_price: price,
          income_account_ref: account.id
        }
        attributes.merge!({ sub_item: true, parent_ref: parent_ref }) if import_as_sub_item

        item_service.create(attributes)

        add_notification('create', product, import_as_sub_item)
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

    def add_notification(operation, product, import_as_sub_item)
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

      @notifications << @text[operation][import_as_sub_item]
    end
  end
end
