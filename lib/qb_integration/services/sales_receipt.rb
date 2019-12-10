module QBIntegration
  module Service
    class SalesReceipt < Base
      attr_reader :order, :payload
      attr_reader :payment_method_service, :line_service, :account_service, :customer_service

      def initialize(config, payload, options = { dependencies: true })
        super("SalesReceipt", config)

        @order = payload[:order] || payload[:return] || payload[:refund]

        if options[:dependencies]
          @payment_method_service = PaymentMethod.new(config, payload)
          @customer_service = Customer.new(config, payload)
          @account_service = Account.new(config)
          @line_service = Line.new(config, payload)
        end
      end

      def find_by_updated_at(page_num)
        raise MissingTimestampParam unless config["quickbooks_since"].present?

        filter = "Where Metadata.LastUpdatedTime>'#{config.fetch("quickbooks_since")}'"
        order_by = "Order By Metadata.LastUpdatedTime"
        query = "Select * from SalesReceipt #{filter} #{order_by}"
        response = quickbooks.query(query, :page => page_num, :per_page => PER_PAGE_AMOUNT)

        new_page = response.count == PER_PAGE_AMOUNT ? page_num.to_i + 1 : 1
        [response.entries, new_page]
      end

      def find_by_order_number
        query = "SELECT * FROM SalesReceipt WHERE DocNumber = '#{order_number}'"
        quickbooks.query(query).entries.first
      end

      def create
        sales_receipt = create_model
        build(sales_receipt)
        quickbooks.create(sales_receipt)
      end

      def update(sales_receipt)
        build(sales_receipt)
        if order[:shipments] && !order[:shipments].empty?
          sales_receipt.tracking_num = shipments_tracking_number.join(", ")
          sales_receipt.ship_method_ref = order[:shipments].last[:shipping_method]
          sales_receipt.ship_date = order[:shipments].last[:shipped_at]
        end
        quickbooks.update(sales_receipt)
      end

      private
        def order_number
          if config['quickbooks_prefix'].nil?
            order[:id] || order[:number]
          else
            "#{config['quickbooks_prefix']}#{(order[:id] || order[:number])}"
          end
        end

        def build(sales_receipt)
          sales_receipt.doc_number = order_number
          sales_receipt.email = order["email"]
          sales_receipt.total = order['totals']['order']

          sales_receipt.txn_date = order['placed_on']

          sales_receipt.ship_address = Address.build(order["shipping_address"])
          sales_receipt.bill_address = Address.build(order["billing_address"])

          sales_receipt.payment_method_id = payment_method_service.matching_payment.id
          sales_receipt.customer_id = customer_service.find_or_create.id
          # Associated as both DepositAccountRef and IncomeAccountRef
          #
          # Quickbooks might return an weird error if the name here is already used
          # by other, I think, quickbooks account
          income_account = nil
          if order["quickbooks_account_name"].present?  || config["quickbooks_account_name"].present?
            income_account_name = order.fetch("quickbooks_account_name", config["quickbooks_account_name"])
            income_account = account_service.find_by_name(income_account_name)
          end

          sales_receipt.line_items = line_service.build_lines(income_account)

          # Default to Undeposit Funds account if no account is set
          #
          # Watch out for errors like:
          #
          #   A business validation error has occurred while processing your
          #   request: Business Validation Error: You need to select a different
          #   type of account for this transaction.
          #
          if order["quickbooks_deposit_to_account_name"].present?  || config["quickbooks_deposit_to_account_name"].present?
            deposit_account_name = order.fetch("quickbooks_deposit_to_account_name", config["quickbooks_deposit_to_account_name"])
            deposit_account = account_service.find_by_name(deposit_account_name)
            sales_receipt.deposit_to_account_id = deposit_account.id
          end
        end

        def shipments_tracking_number
          order[:shipments].map do |shipment|
            shipment[:tracking]
          end
        end
    end
  end
end
