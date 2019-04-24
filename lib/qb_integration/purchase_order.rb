module QBIntegration
  class PurchaseOrder < Base
    attr_accessor :purchase_order

    def initialize(message = {}, config)
      super
      @purchase_order = payload[:purchase_order]
    end

    def create
      purchase_order = purchase_order_service.create
      text = "Created Quickbooks Purchase Order #{purchase_order.id}"
      [200, text]
    end
  end
end
