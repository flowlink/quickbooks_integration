module QBIntegration
  class Order < Base
    attr_accessor :order

    def initialize(message = {}, config)
      super
      @order = payload['order']
    end

    def sync
      if sales_receipt = sales_receipt_service.find_by_order_number
        case message_name
        when "order:new"
          raise AlreadyPersistedOrderException.new(
            "Got 'order:new' message for order #{order[:number]} that already has a
            sales receipt with id: #{sales_receipt.id}"
          )
        when "order:canceled"
          credit_memo = credit_memo_service.create_from_receipt sales_receipt
          text = "Created Quickbooks Credit Memo #{credit_memo.id} for canceled order #{sales_receipt.doc_number}"
          [200, notification(text)]
        when "order:updated"
          sales_receipt = sales_receipt_service.update sales_receipt
          [200, notification("Updated Quickbooks Sales Receipt #{sales_receipt.doc_number}")]
        end
      else
        case message_name
        when "order:new", "order:updated"
          sales_receipt = sales_receipt_service.create
          text = "Created Quickbooks Sales Receipt #{sales_receipt.id} for order #{sales_receipt.doc_number}"
          [200, notification(text)]
        else
          raise AlreadyPersistedOrderException.new(
            "Got 'order:canceled' message for order #{order[:number]} that already has no
            sales receipt"
          )
        end
      end
    end

    def notification(text)
      { 'message_id' => message_id,
        'notifications' => [
          {
            'level' => 'info',
            'subject' => text,
            'description' => text
          }
        ]
      }.with_indifferent_access
    end
  end
end
