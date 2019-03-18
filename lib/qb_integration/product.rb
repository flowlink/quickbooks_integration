module QBIntegration
  class Product < Base
    attr_reader :product_payload

    def initialize(message = {}, config)
      super
      @product_payload = @product = @payload[:product]
    end

    def import
      load_configs
      if @product['variants'] && !@product['variants'].empty?
        @product.fetch(:variants, []).collect.with_index {|variant, index|
          # TODO: Set up better way for clients to specify how to handle sku/name of variant's without a sku/name
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
      else
        import_product(@product)
      end
      [200, @notification]
    end

    private

    def use_quickbooks_categories?
      @config.fetch('use_product_categories').to_s == '1'
    end

    def load_configs
      @income_account_id = account_id('quickbooks_income_account')
      @inventory_costing = (@config.fetch("quickbooks_track_inventory", false).to_s == '1')

      if @inventory_costing
        @inventory_account_id = account_id('quickbooks_inventory_account')
        @cogs_account_id = account_id('quickbooks_cogs_account')
      end
    end

    def account_id(account_name)
      account_service.find_by_name(@config.fetch(account_name)).id
    end

    def attributes(product, is_update = false)
      attrs = {
        name: product[:name],
        sku: product[:sku],
        description: product[:description],
        unit_price: product[:price],
        purchase_cost: product[:cost_price],
        purchase_desc: product[:purchase_description],
        # purchase_tax_included?: product[:purchase_tax_included],
        # taxable?: product[:taxable],
        # sales_tax_included?: product[:sales_tax_included],
        income_account_id: @income_account_id
      }

      # TODO: Need to add support for item creation as a SERVICE_TYPE
      if !@inventory_costing && !is_update
        attrs[:type] = Quickbooks::Model::Item::NON_INVENTORY_TYPE
      end

      # Test accounts do not support track_inventory feature
      if @inventory_costing && !is_update
        quantity = 0
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

      if use_category?(product)
        attrs[:sub_item] = true
        attrs[:parent_ref] = category_id(product)
      end

      attrs
    end

    def import_as_sub_item?(product)
      product[:sku] != @product[:sku]
    end

    def use_category?(product)
      # Check on field specifying category or not
      product[:parent_name] && product[:parent_name] != ''
    end

    def category_id(product)
      unless category = item_service.find_category_by_name(product[:parent_name])
        # NOTE: We only support creating top level categories right now. Nested categories is a future update
        cat = {
          SubItem: false, 
          Type: Quickbooks::Model::Item::CATEGORY_TYPE,
          Name: product[:parent_name]
        }
        category = item_service.create_category(cat)
      end

      category.id
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
        'create' => "Product %s imported to QuickBooks.",
        'update' => "Product %s updated on QuickBooks."
      }
    end

    def time_now
      Time.now.utc
    end
  end
end
