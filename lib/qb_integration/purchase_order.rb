module QBIntegration
  class PurchaseOrder < Base
    attr_accessor :purchase_order

    def initialize(message = {}, config)
      super
      @purchase_order = payload[:purchase_order]
    end

    def create
      response = purchase_order_service.create
      created_po = purchase_order
      created_po[:qbo_id] = response.id
      text = "Created QuickBooks Purchase Order with number #{response.doc_number} and with id #{response.id}"
      [200, text, created_po]
    end

    def update
      response, action = purchase_order_service.update
      updated_po = purchase_order
      updated_po[:qbo_id] = response.id
      text = "#{action} QuickBooks Purchase Order with number #{response.doc_number} and with id #{response.id}"
      [200, text, updated_po]
    end
  end
end