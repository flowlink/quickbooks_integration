module QBIntegration
  class Product < Base
    attr_reader :product_payload

    def initialize(message = {}, config)
      super

      @product_payload = @product = @payload[:product]
    end

    def import
      load_configs
      #import_product(@product)
      @product.fetch(:variants, []).collect.with_index {|variant, index|
        if variant[:sku].to_s.empty?
          variant[:sku] = @product[:sku] + "_" + index.to_s
        end
        if variant[:description].to_s.empty?
          variant[:description] = @product[:description]
        end
        if variant[:name].to_s.empty?
          variant[:name] = @product[:name] + " " + index.to_s
        end
        import_product(variant)
      }

      [200, @notification]
    end

    private
    def load_configs
      @income_account_id = account_id('quickbooks_income_account')
      @inventory_costing = (@config.fetch("quickbooks_track_inventory", false).to_s == '1')

      if @inventory_costing
        @inventory_account_id = account_id('quickbooks_inventory_account')
        @cogs_account_id = account_id('quickbooks_cogs_account')
      end
    end

    def account_id(account_name)
      name = @product[account_name] || @config.fetch(account_name)
      account_service.find_by_name(name).id
    end

    def attributes(product, is_update = false)
      attrs = {
        name: product[:name],
        sku: product[:sku],
        description: product[:description],
        unit_price: product[:price],
        purchase_cost: product[:cost_price],
        income_account_id: @income_account_id
      }

      if !@inventory_costing && !is_update
        attrs[:type] = Quickbooks::Model::Item::NON_INVENTORY_TYPE
      end

      # Test accounts do not support track_inventory feature
      if @inventory_costing && !is_update
        quantity = 1
        if !product[:quantity].nil? && !product[:quantity].blank?
          quantity = product[:quantity].to_i
        end
        attrs[:quantity_on_hand] = quantity

        attrs[:track_quantity_on_hand] = true
        attrs[:inv_start_date] = time_now
        attrs[:type] = Quickbooks::Model::Item::INVENTORY_TYPE
        attrs[:asset_account_id] = @inventory_account_id
        attrs[:expense_account_id] = @cogs_account_id
      end

      if import_as_sub_item?(product)
        #attrs[:sub_item] = true
        #attrs[:parent_ref] = parent_ref
      end

      attrs
    end

    def import_as_sub_item?(product)
      product[:sku] != @product[:sku]
    end

    def import_product(product)
      if item = item_service.find_by_sku(product[:sku])
        item_service.update(item, attributes(product, true))
        add_notification('update', product)
      else
        item_service.create(attributes(product, false))
        add_notification('create', product)
      end
    end

    def parent_ref
      @parent_ref ||= item_service.find_by_sku(@product[:sku]).id
    end

    def add_notification(operation, product)
      @notification = @notification.to_s + text[operation] % product[:sku] + " "
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
