module QBIntegration
  class Stock < Base
    attr_reader :item

    def initialize(message = {}, config)
      super
      @item = item_service.find_by_sku message[:payload][:sku], "Name, QtyOnHand"
    end
  end
end
