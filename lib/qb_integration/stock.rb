module QBIntegration
  class Stock < Base
    attr_reader :item, :items, :name

    def initialize(message = {}, config)
      super

      @name = message[:sku] || message[:product_id]

      if name.present?
        @item = item_service.find_by_sku name
      else
        @items = item_service.find_by_updated_at
      end
    end

    def inventories
      items.map do |inventory|
        {
          id: "qbs-#{inventory.name}",
          product_id: inventory.sku,
          quantity: inventory.quantity_on_hand.to_i
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

    def last_modified_date
      items.last.meta_data.last_updated_time.utc.iso8601
    end
  end
end
