module QBIntegration
  class Payment < Base
    attr_accessor :payment

    def initialize(message = {}, config)
      super
      @payment = payload[:payment]
    end

    def create
      return [500, "Payment with reference number #{payment[:id]} already exists"] if find_payment

      if identifier_exists
        created_payment, number, name = payment_service.create_payment
        text = "Created QuickBooks Payment #{created_payment.id} for #{name} #{number}"
      else
        created_payment = payment_service.create_unapplied_payment
        text = "Created unapplied QuickBooks Payment #{created_payment.id}"
      end
      
      [200, text]
    end

    private

    def find_payment
      payment_service.find_payment
    end

    def identifier_exists
      # Possible options for Linked Transactions are: Expense, Check, CreditCardCredit, JournalEntry, CreditMemo, Invoice
      # Only invoice currently
      payment[:invoice_id] || payment[:invoice_number] || payment[:reference_number]
    end
  end
end

