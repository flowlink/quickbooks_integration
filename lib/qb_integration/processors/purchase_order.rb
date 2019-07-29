module QBIntegration
  module Processor
    class PurchaseOrder
      include Helper
      attr_reader :purchase_order

      def initialize(purchase_order)
        @purchase_order = purchase_order
      end

      def as_flowlink_hash
        puts "*" * 100
        puts purchase_order.inspect
        puts "*" * 100
        {
          id: purchase_order.id,
          doc_number: purchase_order.doc_number,
          last_updated_time: purchase_order.meta_data["last_updated_time"],
          quantity_received: 24 #TODO: Update with real value
        }
      end

    end
  end
end
