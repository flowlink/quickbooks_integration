module QBIntegration
  module Processor
    class PurchaseOrder
      include Helper
      attr_reader :purchase_order, :payload

      def initialize(purchase_order, payload)
        @purchase_order = purchase_order
        @payload = payload
      end

      def as_flowlink_hash
        {
          id: purchase_order.id,
          doc_number: purchase_order.doc_number,
          last_updated_time: purchase_order.meta_data["last_updated_time"],
          received_items: payload["purchase_order"]["received_items"],
          quantity_received_in_qbo: payload["purchase_order"]["received_items"],
        }.compact
      end
    end
  end
end
