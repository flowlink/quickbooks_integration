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
          total: payment.total,
          unapplied_amount: payment.unapplied_amount,
          process_payment: payment.process_payment,
          exchange_rate: payment.exchange_rate,
          customer: build_ref(payment.customer_ref),
          ar_account: build_ref(payment.ar_account_ref),
          payment_method: build_ref(payment.payment_method_ref),
          deposit_to_account: build_ref(payment.deposit_to_account_ref),
          currency: build_ref(payment.currency_ref),
          qbo_linked_invoice_id: @invoice ? @invoice.id : nil,
          qbo_linked_invoice_number: @invoice ? @invoice.doc_number : nil
        }.compact
      end

      private

      def build_line_items(items)
        items.to_a.map do |item|
          if txn = item.linked_transactions.find { |txn| txn.txn_type == 'Invoice' }
            @invoice = Service::Invoice.new(@config, {}, { dependencies: false }).find_by_id(txn.txn_id)
          end
          Processor::PaymentLineItem.new(item, @invoice).as_flowlink_hash
        end
      end

    end
  end
end
