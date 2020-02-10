module QBIntegration
  class Payment < Base
    attr_accessor :payment, :new_page_number, :new_or_updated_payments

    def initialize(message = {}, config)
      super
      @payment = payload[:payment]
    end

    def create
      return [500, "Payment with reference number #{payment[:id]} already exists"] if find_payment

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

    def get
      now = Time.now.utc.iso8601
      @new_or_updated_payments, @new_page_number = payment_service.find_by_updated_at(page_number)
      summary = "Retrieved #{@new_or_updated_payments.count} payments from QuickBooks Online"

       [summary, new_page_number, since(now), code]
    end

     def build_payment(raw_payment)
      Processor::Payment.new(raw_payment, config).as_flowlink_hash
    end

    private

    def find_payment
      payment_service.find_payment
    end

    def identifier
      # Possible options for Linked Transactions are: Expense, Check, CreditCardCredit, JournalEntry, CreditMemo, Invoice
      # Only invoice currently
      payment[:invoice_id] || payment[:invoice_number] || payment[:reference_number]
    end

    def page_number
      config.fetch("quickbooks_page_num").to_i || 1
    end

     def since(now)
      new_page_number == 1 ? now : config.fetch("quickbooks_since")
    end

    def allow_unapplied_payment?
      payment.has_key?('allow_unapplied_payment') || config.has_key?('allow_unapplied_payment')
    end

     def code
      new_page_number == 1 ? 200 : 206
    end
    
  end
end

