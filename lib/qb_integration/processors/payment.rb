module QBIntegration
  module Processor
    class Payment
      include Helper
      attr_reader :payment

      def initialize(payment, config)
        @payment = payment
        @config = config
      end

      def as_flowlink_hash
        {
          id: payment.id,
          sync_token: payment.sync_token,
          txn_date: payment.txn_date,
          private_note: payment.private_note,
          txn_status: payment.txn_status,
          line_items: build_line_items(payment.line_items),
          payment_ref_number: payment.payment_ref_number,
          credit_card_payment: payment.credit_card_payment,
          amount: payment.total.to_f,
          unapplied_amount: payment.unapplied_amount.to_f,
          process_payment: payment.process_payment,
          exchange_rate: payment.exchange_rate,
          customer: customer,
          ar_account: build_ref(payment.ar_account_ref),
          payment_method: build_ref(payment.payment_method_ref),
          deposit_to_account: build_ref(payment.deposit_to_account_ref),
          currency: build_ref(payment.currency_ref),
          qbo_linked_invoice_id: qbo_linked_invoice_id,
          qbo_linked_invoice_number: qbo_linked_invoice_number
        }.compact
      end

      private

      def qbo_linked_invoice_id
        @invoice ? @invoice.id : nil
      end

      def qbo_linked_invoice_number
        @invoice ? @invoice.doc_number : nil
      end

      def build_line_items(items)
        items.to_a.map do |item|
          if txn = item.linked_transactions.find { |txn| txn.txn_type == 'Invoice' }
            @invoice = Service::Invoice.new(@config, {}, { dependencies: false }).find_by_id(txn.txn_id)
          end
          Processor::PaymentLineItem.new(item, @invoice).as_flowlink_hash
        end
      end

      def customer
        found_customer = Service::Customer.new(@config, {}).find_by_id(payment.customer_ref.value)
        QBIntegration::Customer.new({}, @config).build_customer(found_customer)
      rescue RecordNotFound => e
        return {}
      end

    end
  end
end
