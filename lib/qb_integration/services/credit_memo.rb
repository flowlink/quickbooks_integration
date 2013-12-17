module QBIntegration
  module Service
    class CreditMemo < Base
      attr_reader :order, :payload
      attr_reader :payment_method_service, :line_service, :account_service, :customer_service

      def initialize(config, payload)
        super("CreditMemo", config)

        @order = payload[:order]
      end

      def create_from_receipt(sales_receipt)
        credit_memo = create_model
        credit_memo.doc_number = sales_receipt.doc_number
        credit_memo.email = sales_receipt.bill_email.address
        credit_memo.total = order[:totals][:order]

        credit_memo.placed_on = order[:updated_at]
        credit_memo.line_items = sales_receipt.line_items

        credit_memo.bill_address = sales_receipt.bill_address
        credit_memo.payment_method_ref = sales_receipt.payment_method_ref
        credit_memo.customer_ref = sales_receipt.customer_ref
        credit_memo.deposit_to_account_ref = sales_receipt.deposit_to_account_ref

        quickbooks.create credit_memo
      end
    end
  end
end
