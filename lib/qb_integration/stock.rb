module QBIntegration
  class Stock < Base
    attr_reader :item

    def initialize(message = {}, config)
      super

      name = message[:sku] || message[:product_id]
      @item = item_service.find_by_sku name, "Name, QtyOnHand"
    end
  end
end
