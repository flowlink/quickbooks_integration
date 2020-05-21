module QBIntegration
  class PurchaseOrder < Base
    attr_accessor :purchase_order

    def initialize(message = {}, config)
      super
      @purchase_order = payload[:purchase_order]
    end

    def create
      po = purchase_order_service.create
      text = "Created Quickbooks Purchase Order #{purchase_order[:id]}"
      purchase_order[:qbo_id] = po.id
      [200, text, purchase_order]
    end

    def update
      response = purchase_order_service.update
      text = "Updated Quickbooks Purchase Order #{purchase_order[:id]}"
      [200, text]
    end
  end
end
