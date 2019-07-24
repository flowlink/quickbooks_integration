module QBIntegration
  class Stock < Base
    attr_reader :item, :items, :name

    def initialize(message = {}, config)
      super
      @name = message[:sku] || message[:product_id]

      if message[:inventory]
        @name = message[:inventory][:product_id] || message[:inventory][:sku]
        @item = item_service.find_by_sku name
        @amount = message[:inventory][:quantity]
        @id = message[:inventory][:id]
      else
        if name.present?
          @item = item_service.find_by_sku name
        else
          @items = item_service.find_by_updated_at
        end
      end
    end

    def set
      set_inventory(item, @amount, @id)

      [200, @notification]
    end

    def set_inventory(item, amount, id)
      item_service.update(item, attributes(amount, true))
      @notification = "Product %s updated on QuickBooks." % id
    end

    def attributes(amount, is_update = false)
      attrs = {
        sku: name,
      }

      quantity = 1
      if !amount.nil? && !amount.blank?
        quantity = amount.to_i
      end
      attrs[:quantity_on_hand] = quantity

      attrs[:track_quantity_on_hand] = true
      attrs[:inv_start_date] = time_now
      attrs[:type] = Quickbooks::Model::Item::INVENTORY_TYPE

      attrs
    end

    def inventories
      items.map do |inventory|
        {
          id: "qbs-#{inventory.name}",
          product_id: inventory.sku,
          quantity: inventory.quantity_on_hand.to_i,
          updated_at: last_modified_date
        }
      end
    end

    def inventory
      {
        id: "qbs-#{item.name}",
        product_id: item.sku,
        quantity: item.quantity_on_hand.to_i
      }
    end

    def time_now
      Time.now.utc
    end

    def last_modified_date
      items.last.meta_data.last_updated_time.utc.iso8601
    end
  end
end
