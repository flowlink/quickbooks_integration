module QBIntegration
  class RefundReceipt < Base
    attr_accessor :refund_receipt

    def initialize(payload, config)
      super
      @refund_receipt = payload[:refund]
    end

    def create
      raise AlreadyPersistedRefundReceiptException.new "Refund with reference number #{refund_receipt[:id]} already exists" if find_refund_receipt

      created_refund = refund_receipt_service.create
      updated_flowlink_refund = refund_receipt
      updated_flowlink_refund[:qbo_id] = created_refund.id
      
      text = "Created QuickBooks Refund Receipt #{created_refund.id}. Reference number is #{created_refund.doc_number}"
      
      [200, text, updated_flowlink_refund]
    end

    private

    def find_refund_receipt
      refund_receipt_service.find_refund_receipt
    end
  end
end

