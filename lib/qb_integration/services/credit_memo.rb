module QBIntegration
  module Service
    class CreditMemo < Base
      attr_reader :order, :payload, :credit_memo
      attr_reader :payment_method_service, :line_service, :account_service, :customer_service

      def initialize(config, payload)
        super("CreditMemo", config)
        @payload = payload
        @order = payload[:order]
        @credit_memo = payload[:credit_memo]
        @customer_service = Customer.new(config, payload)
      end

      def create
        credit_memo = create_model
        build(credit_memo)
        quickbooks.create(credit_memo)
      end

      def update(memo)
        build(memo)
        quickbooks.update(memo)
      end

      def build(memo)
        memo.doc_number = memo_number
        memo.customer_id = customer_service.find_or_create.id
        memo.line_items = line_service.build_credit_memo_lines(memo)
      end

      def memo_number
        if config['quickbooks_prefix'].nil?
          credit_memo[:id] || credit_memo[:number]
        else
          "#{config['quickbooks_prefix']}#{(credit_memo[:id] || credit_memo[:number])}"
        end
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

        quickbooks.create(credit_memo)
      end

      def create_from_return(return_authorization, sales_receipt)
        credit_memo = create_model
        build_from_return(credit_memo, return_authorization, sales_receipt)
        quickbooks.create(credit_memo)
      end

      def find_by_number(number)
        query = "SELECT * FROM CreditMemo WHERE DocNumber = '#{number}'"
        quickbooks.query(query).entries.first
      end

      def update(credit_memo, return_authorization, sales_receipt)
        build_from_return(credit_memo, return_authorization, sales_receipt)
        quickbooks.update(credit_memo)
      end

      private
        def line_service
          Service::Line.new(config, payload)
        end

        def item_service
          Service::Item.new(config)
        end

        def build_from_return(credit_memo, return_authorization, sales_receipt)
          credit_memo.doc_number = return_authorization[:number]
          credit_memo.email = sales_receipt.bill_email.address
          credit_memo.total = return_authorization[:amount]

          credit_memo.placed_on = return_authorization[:created_at]

          lines = line_service.build_from_inventory_units

          # Check if it's necessary to add extra line to adjust and match return
          # authorization amount
          difference = return_authorization[:totals][:refund].to_f - (lines.map(&:amount).map(&:to_f).inject(:+) || 0.0)
          if difference != 0
            lines += [return_adjust_line(difference)]
          end

          credit_memo.line_items = lines

          credit_memo.bill_address = sales_receipt.bill_address
          credit_memo.payment_method_ref = sales_receipt.payment_method_ref
          credit_memo.customer_ref = sales_receipt.customer_ref
          credit_memo.deposit_to_account_ref = sales_receipt.deposit_to_account_ref
        end

        def return_adjust_line(amount)
          line = Quickbooks::Model::Line.new
          line_item = {}

          line.amount = line_item[:price] = amount
          line.description = line_item[:description] = line_item[:sku] = "Return adjustment line"

          line.sales_item! do |sales_item|
            sales_item.item_id = item_service.find_or_create_by_sku(line_item).id
            sales_item.quantity = 1
            sales_item.unit_price = amount
          end

          line
        end
    end
  end
end
