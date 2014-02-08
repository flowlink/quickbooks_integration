module QBIntegration
  module Service
    class SalesReceipt < Base
      attr_reader :order, :payload
      attr_reader :payment_method_service, :line_service, :account_service, :customer_service

      def initialize(config, payload, options = { dependencies: true })
        super("SalesReceipt", config)

        @order = payload[:order]
        @original = payload[:original]

        if options[:dependencies]
          @payment_method_service = PaymentMethod.new config, payload
          @customer_service = Customer.new config, payload
          @account_service = Account.new config
          @line_service = Line.new config, payload
        end
      end

      def find_by_order_number
        query = "SELECT * FROM SalesReceipt WHERE DocNumber = '#{order[:number]}'"
        quickbooks.query(query).entries.first
      end

      def create
        sales_receipt = create_model
        build sales_receipt
        quickbooks.create sales_receipt
      end

      def update(sales_receipt)
        build sales_receipt
        sales_receipt.tracking_num = shipments_tracking_number.join(", ")
        quickbooks.update sales_receipt
      end

      private
        def build(sales_receipt)
          sales_receipt.doc_number = order["number"]
          sales_receipt.email = order["email"]
          sales_receipt.total = order['totals']['order']

          sales_receipt.placed_on = order['placed_on']

          sales_receipt.ship_address = Address.build order["shipping_address"]
          sales_receipt.bill_address = Address.build order["billing_address"]

          sales_receipt.payment_method_ref = payment_method_service.matching_payment.id
          sales_receipt.customer_ref = customer_service.find_or_create.id

          # Associated as both DepositAccountRef and IncomeAccountRef
          # TODO Do we have to associate account_name to receipt lines and
          # deposit_to_account_name to the sales receipt itself? (as in the
          # previous endpoint version)
          #
          # Quickbooks might return an weird error if the name here is already used
          # by other, I think, quickbooks account
          account = account_service.find_by_name config.fetch("quickbooks.account_name")

          sales_receipt.line_items = line_service.build_lines account

          # TODO We need a check here. Users might want to just use the default
          # undeposit funds account. That should be the default behaviour which
          # we can accomplish by just not setting any account ref
          # sales_receipt.deposit_to_account_ref = account.id
        end

        def shipments_tracking_number
          order[:shipments].map do |shipment|
            shipment[:tracking]
          end
        end
    end
  end
end
