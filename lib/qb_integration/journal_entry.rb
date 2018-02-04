module QBIntegration
  class JournalEntry < Base
    attr_reader :journal_entry_payload

    def initialize(message = {}, config)
      super

      @journal_entry_payload = @journal_entry = @payload[:journal_entry]
    end

    def import
      load_configs
      import_journal_entry(@journal_entry)
      [200, @notification]
    end

    private
    def load_configs
      @account_id = account_id(@config.fetch(account_description))
    end

    def account_id(account_name)
      account_service.find_by_name(account_name).id
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

    def import_journal_entry(journal_entry)
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
