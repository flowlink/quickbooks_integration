module QBIntegration
  class Order < Base
    attr_accessor :order

    def initialize(message = {}, config)
      super
      @order = payload[:order]
    end

    def create
      if sales_receipt = sales_receipt_service.find_by_order_number
        raise AlreadyPersistedOrderException.new(
          "Order #{order[:id]} already has a sales receipt with id: #{sales_receipt.id}"
        )
      end

      sales_receipt = sales_receipt_service.create
      text = "Created QuickBooks Sales Receipt #{sales_receipt.id} for order #{sales_receipt.doc_number}"
      [200, text]
    end

    def update
      sales_receipt = sales_receipt_service.find_by_order_number

      if !sales_receipt.present? && config[:quickbooks_create_or_update].to_s == "1"
        sales_receipt = sales_receipt_service.create
        [200, "Created QuickBooks Sales Receipt #{sales_receipt.doc_number}"]
      elsif !sales_receipt.present?
        raise RecordNotFound.new "QuickBooks Sales Receipt not found for order #{order[:number]}"
      else
        sales_receipt = sales_receipt_service.update sales_receipt
        [200, "Updated QuickBooks Sales Receipt #{sales_receipt.doc_number}"]
      end
    end

    def cancel
      unless sales_receipt = sales_receipt_service.find_by_order_number
        raise RecordNotFound.new "QuickBooks Sales Receipt not found for order #{order[:number]}"
      end

      credit_memo = credit_memo_service.create_from_receipt sales_receipt
      text = "Created QuickBooks Credit Memo #{credit_memo.id} for canceled order #{sales_receipt.doc_number}"
      [200, text]
    end
  end
end
