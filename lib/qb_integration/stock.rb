module QBIntegration
  class Stock < Base
    attr_reader :item, :items, :name

    def initialize(message = {}, config)
      super

      @name = message[:sku] || message[:product_id]

      if name.present?
        @item = item_service.find_by_sku name, "Name, QtyOnHand"
      else
        @items = item_service.find_by_updated_at
      end
    end

    def inventories
      items.each do |inventory|
        {
          id: "qbs-#{inventory.name}",
          product_id: inventory.name,
          quantity: inventory.quantity_on_hand
        }
      end
    end

    def last_modified_date
      items.last.meta_data.last_updated_time
    end
  end
end
