module QBIntegration
  module Service
    class Payment < Base
      attr_accessor :vendor, :flowlink_payment

      def initialize(config, payload)
        super("Payment", config)
        @flowlink_payment = payload[:payment]
        @vendor = payload[:vendor]

        @account_service = Account.new(config)
      end

      def create_payment
        transaction_cannot_be_paid
        payment = create_model
        build(payment)
        add_linked_txn(payment)

        created_payment = quickbooks.create(payment)
        [created_payment, qbo_transaction.doc_number, get_transaction_name]
      end

      def create_unapplied_payment
        payment = create_model
        build(payment)
        quickbooks.create(payment)
      end

      def find_payment
        find_by_reference_number(flowlink_payment[:id])
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("id", "=", id)
        payment = @quickbooks.query("select * from Payment where #{clause}").entries.first
        raise RecordNotFound.new "No Payment '#{id}' defined in service" unless payment
        payment
      end

      def find_by_updated_at(page_num)
        raise MissingTimestampParam unless config["quickbooks_poll_stock_timestamp"].present?

         filter = "Where Metadata.LastUpdatedTime > '#{config.fetch("quickbooks_poll_stock_timestamp")}'"
        order = "Order By Metadata.LastUpdatedTime"
        query = "select * from Payment #{filter} #{order}"

         if page_num
          response = quickbooks.query(query, :page => page_num, :per_page => PER_PAGE_AMOUNT)
          new_page = response.count == PER_PAGE_AMOUNT ? page_num.to_i + 1 : 1
          [response.entries, new_page]
        else
          response = quickbooks.query(query)
          response.entries
        end        
      end

      private

      def transaction_cannot_be_paid
        if qbo_transaction.balance.to_f == 0.0
          raise TransactionMustBeOpen.new("#{get_transaction_name} #{qbo_transaction.doc_number} is already Paid")
        end
      end

      def deposit_to_account_parameter
        @flowlink_payment['deposit_to_account'] || config['deposit_to_account'] || nil
      end

      def find_by_reference_number(reference_number)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("PaymentRefNum", "=", reference_number)
        @quickbooks.query("select * from Payment where #{clause}").entries.first
      end

      def qbo_transaction
        @transaction ||= find_transaction
      end

      def build(payment)
        customer = find_qbo_customer
        if deposit_to_account_parameter
          deposit_to_account = @account_service.find_by_name(deposit_to_account_parameter)
          payment.deposit_to_account_id = deposit_to_account.id
        end

        payment.txn_date = flowlink_payment[:transaction_date] if flowlink_payment[:transaction_date]
        payment.customer_id = customer.id
        payment.total = flowlink_payment[:amount]
        payment.payment_method_id = find_payment_method.id
        payment.payment_ref_number = flowlink_payment[:id]
      end

      def add_linked_txn(payment)
        # Only 1 line per payment as of now - might need to add more later
        payment.line_items = Line.new(config, {}).build_payment_lines(flowlink_payment, qbo_transaction)
      end

      def find_transaction
        # Currently we only find invoices, but we can add more transaction searches here
        invoice_payload = {
          invoice:{
            id: flowlink_payment[:invoice_id],
            number: flowlink_payment[:invoice_number]
          }
        }
        unless invoice = Invoice.new(config, invoice_payload).find_by_invoice_number
          raise RecordNotFound.new("No Invoice #{flowlink_payment[:invoice_d] || flowlink_payment[:invoice_number]} found.")
        end

        invoice
      end

      def get_transaction_name
        qbo_transaction.class.name.split('::').last
      end

      def find_payment_method
        # Payment Method class expects order key
        order_payload = {
          order: {
            "payments" => [{ "payment_method" => flowlink_payment[:payment_method] }]
          }
        }
        PaymentMethod.new(config, order_payload).matching_payment
      end

      def find_qbo_customer
        unless customer = Customer.new(config, flowlink_payment).find_customer
          raise RecordNotFound.new "No Customer found with given name: #{flowlink_payment[:customer][:name]}"
        end

        customer
      end
    end
  end
end
