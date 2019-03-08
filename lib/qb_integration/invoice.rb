module QBIntegration
  class Invoice < Base
    attr_accessor :flowlink_invoice

    def initialize(message = {}, config)
      super
      @flowlink_invoice = payload[:invoice]
    end

    def create
      if qb_invoice = invoice_service.find_by_invoice_number
        raise AlreadyPersistedOrderException.new("Invoice #{flowlink_invoice[:id]} already exists")
      end

      invoice = invoice_service.create
      text = "Created Quickbooks Invoice #{invoice.doc_number}"
      [200, text]
    end

    def update
      qb_invoice = invoice_service.find_by_invoice_number

      if !qb_invoice.present? && config[:quickbooks_create_or_update].to_s == "1"
        invoice = invoice_service.create
        [200, "Created Quickbooks Invoice #{invoice.doc_number}"]
      elsif !qb_invoice.present?
        raise RecordNotFound.new "Quickbooks invoice not found for invoice #{invoice[:number] || invoice[:id]}"
      else
        invoice = invoice_service.update qb_invoice
        [200, "Updated Quickbooks invoice #{invoice.doc_number}"]
      end
    end

    def cancel
      # unless sales_receipt = sales_receipt_service.find_by_order_number
      #   raise RecordNotFound.new "Quickbooks Sales Receipt not found for order #{order[:number]}"
      # end

      # credit_memo = credit_memo_service.create_from_receipt sales_receipt
      # text = "Created Quickbooks Credit Memo #{credit_memo.id} for canceled order #{sales_receipt.doc_number}"
      # [200, text]
    end
  end
end
