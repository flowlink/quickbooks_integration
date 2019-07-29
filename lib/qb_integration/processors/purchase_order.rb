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
          quantity_received: payload["purchase_order"]["quantity_received"],
          quantity_received_in_qbo: quantity_received_in_qbo
        }.compact
      end

      private

      def quantity_received_in_qbo
        purchase_order.line_items.map do | line_item|
          {
            line_item_name: line_item.item_based_expense_line_detail["item_ref"]["name"],
            quantity_received_so_far: payload["purchase_order"]["quantity_received"]
          }
        end
      end

    end
  end
end
