module QBIntegration
  class RefundReceipt < Base
    attr_accessor :refund_receipt

    def initialize(payload, config)
      super
      @refund_receipt = payload[:refund_receipt]
    end

    def create
      return [500, "Payment with reference number #{refund_receipt[:id]} already exists"] if find_refund_receipt

      if identifier
        created_payment, number, name = payment_service.create_payment
        text = "Created QuickBooks Payment #{created_payment.id} for #{name} #{number}. Payment reference number is #{created_payment.payment_ref_number}"
      else
        raise UnnappliedPaymentsNotAllowed unless allow_unapplied_payment?
        created_payment = payment_service.create_unapplied_payment
        text = "Created unapplied QuickBooks Payment #{created_payment.id}. Payment reference number is #{created_payment.payment_ref_number}"
      end
      
      [200, text]
    end

     def build_payment(raw_payment)
      Processor::Payment.new(raw_payment, config).as_flowlink_hash
    end

    private

    def find_refund_receipt
      refund_receipt_service.find_refund_receipt
    end

    def identifier
      # Possible options for Linked Transactions are: Expense, Check, CreditCardCredit, JournalEntry, CreditMemo, Invoice
      # Only invoice currently
      payment[:invoice_id] || payment[:invoice_number] || payment[:reference_number]
    end

    def page_number
      config.fetch("quickbooks_page_num").to_i || 1
    end

     def since
      new_page_number == 1 ? Time.now.utc.iso8601 : config.fetch("quickbooks_since")
    end

    def allow_unapplied_payment?
      payment.has_key?('allow_unapplied_payment') || config.has_key?('allow_unapplied_payment')
    end

     def code
      new_page_number == 1 ? 200 : 206
    end
    
  end
end

