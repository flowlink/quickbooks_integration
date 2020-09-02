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
          service = import_product(variant)
        }
      else
        service = import_product(@product)
      end
      [200, @notification ]
    end

    def update_sku
      if item = item_service.find_by_sku(@product[:sku])
        attrs = {
          sku: @product[:update_sku],
          name: @product[:name],
          sku: @product[:update_sku],
          description: @product[:description],
          purchase_desc: @product[:purchase_description]
        }
        item_service.update(item, attrs)
        add_notification('update', @product)
      else
        raise RecordNotFound.new "QuickBooks product not found for sku#{@product[:sku]}"
      end
      [200, @notification, { id: @product[:id], sku: @product[:update_sku] }]
    end

    private

    def load_configs
      @inventory_costing = track_inventory

      if @inventory_costing
        @inventory_account_id = account_id('quickbooks_inventory_account')
        @cogs_account_id = account_id('quickbooks_cogs_account')
      end
    end

    def track_inventory
      @product_payload.fetch("quickbooks_track_inventory", false).to_s == '1' ||
        @config.fetch("quickbooks_track_inventory", false).to_s == '1'
    end

    def force_date_update
      @product_payload.fetch("quickbooks_inventory_date_update", false).to_s == '1' ||
        @config.fetch("quickbooks_inventory_date_update", false).to_s == '1'
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
        purchase_desc: product[:purchase_description],
        # purchase_tax_included?: product[:purchase_tax_included],
        # taxable?: product[:taxable],
        # sales_tax_included?: product[:sales_tax_included],
      }

      # Income account needed if item is being used for sales receipts and invoices
      attrs[:income_account_id] = account_id('quickbooks_income_account') if account_check('quickbooks_income_account')
      # Expense account needed if item is being used for purchase orders
      attrs[:expense_account_id] = account_id('quickbooks_cogs_account') if account_check('quickbooks_cogs_account')

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
        attrs[:inv_start_date] = product[:inventory_start_date] || time_now
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

      attrs[:inv_start_date] = product[:inventory_start_date] if force_date_update

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
          sub_item: false,
          type: Quickbooks::Model::Item::CATEGORY_TYPE,
          name: product[:parent_name]
        }
        category = item_service.create(cat)
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
      item_service
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

    def account_check(name)
      if @product_payload.fetch(name, false) || @config.fetch(name, false)
        true
      else
        false
      end
    end
  end
end
