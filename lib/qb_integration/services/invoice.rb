module QBIntegration
  module Service
    class Invoice < Base
      attr_reader :flowlink_invoice, :payload
      attr_reader :invoice_line_service, :account_service, :customer_service

      def initialize(config, payload, options = { dependencies: true })
        super("Invoice", config)

        @flowlink_invoice = payload[:invoice]

        if options[:dependencies]
          @customer_service = Customer.new config, payload
          @account_service = Account.new config
          @invoice_line_service = InvoiceLine.new config, payload
        end
      end

      def find_by_invoice_number
        query = "SELECT * FROM Invoice WHERE DocNumber = '#{invoice_number}'"
        quickbooks.query(query).entries.first
      end

      def find_by_id(id)
        query = "SELECT * FROM Invoice WHERE id = '#{id}'"
        quickbooks.query(query).entries.first
      end

      def find_by_updated_at(page_num)
        raise MissingTimestampParam unless config["quickbooks_since"].present?
      
        filter = "Where Metadata.LastUpdatedTime>'#{config.fetch("quickbooks_since")}'"
        order_by = "Order By Metadata.LastUpdatedTime"
        query = "Select * from Invoice #{filter} #{order_by}"
        response = quickbooks.query(query, :page => page_num, :per_page => PER_PAGE_AMOUNT)
      
        new_page = response.count == PER_PAGE_AMOUNT ? page_num.to_i + 1 : 1
        [response.entries, new_page]
      end

      def create
        invoice = create_model
        build(invoice)
        quickbooks.create(invoice)
      end

      def update(invoice)
        build(invoice)

        # Will there ever be shipments on an invoice???

        # if flowlink_invoice[:shipments] && !flowlink_invoice[:shipments].empty?
        #   invoice.tracking_num = shipments_tracking_number.join(", ")
        #   invoice.ship_method_ref = flowlink_invoice[:shipments].last[:shipping_method]
        #   invoice.ship_date = flowlink_invoice[:shipments].last[:shipped_at]
        # end

        quickbooks.update(invoice)
      end

      private
        def invoice_number
          if config['quickbooks_prefix'].nil?
            flowlink_invoice[:number] || flowlink_invoice[:id]
          else
            "#{config['quickbooks_prefix']}#{(flowlink_invoice[:number] || flowlink_invoice[:id])}"
          end
        end

        def build(invoice)
          invoice.doc_number = invoice_number
          invoice.customer_id = customer_service.find_or_create.id
          invoice.txn_date = flowlink_invoice['created_at']
          invoice.due_date = flowlink_invoice['due_date']
          invoice.total = flowlink_invoice['grand_total']
          invoice.tracking_num = shipments_tracking_number.join(", ")

          # TODO: Confirm if this needs to be set?
          invoice.bill_email = Quickbooks::Model::EmailAddress.new(flowlink_invoice['email'])

          # If ShipAddr, BillAddr, or both are not provided, 
          # the appropriate customer address from Customer is used to fill those values.
          invoice.shipping_address = Address.build(flowlink_invoice['shipping_address'])
          invoice.billing_address = Address.build(flowlink_invoice['billing_address'])
          
          addAccounts(invoice)
          
          # Used when creating a new product
          income_account = nil
          if config["quickbooks_account_name"].present?
            income_account = account_service.find_by_name(config.fetch("quickbooks_account_name"))
          end

          invoice.line_items = invoice_line_service.build_lines(income_account)
        end

        def addAccounts(invoice)
          if config["quickbooks_ar_account_name"].present?
            deposit_account = account_service.find_by_name(config.fetch("quickbooks_ar_account_name"))
            invoice.ar_account_id = deposit_account.id
          end

          if config["quickbooks_deposit_to_account_name"].present?
            deposit_account = account_service.find_by_name(config.fetch("quickbooks_deposit_to_account_name"))
            invoice.deposit_to_account_id = deposit_account.id
          end
        end

        def shipments_tracking_number
          flowlink_invoice[:shipments].to_a.map do |shipment|
            shipment[:tracking]
          end
        end
    end
  end
end
