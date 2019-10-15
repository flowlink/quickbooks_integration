module QBIntegration
  module Service
    class RefundReceipt < Base
      attr_reader :refund, :payload

      def initialize(config, payload)
        super("RefundReceipt", config)

        @refund = payload[:refund]

        @payment_method_service = PaymentMethod.new(config, payload)
        @customer_service = Customer.new(config, payload)
        @account_service = Account.new(config)

        new_payload = {order: payload['refund']}
        @line_service = Line.new(config, new_payload)
      end

      def find_refund_receipt
        query = "SELECT * FROM RefundReceipt WHERE DocNumber = '#{refund_receipt_number}'"
        quickbooks.query(query).entries.first
      end

      def create
        refund_receipt = create_model
        build(refund_receipt)
        quickbooks.create(refund_receipt)
      end

      private
        def refund_receipt_number
          if config['quickbooks_prefix'].nil?
            refund[:id] || refund[:number]
          else
            "#{config['quickbooks_prefix']}#{(refund[:id] || refund[:number])}"
          end
        end

        def build(refund_receipt)
          refund_receipt.doc_number = refund_receipt_number
          refund_receipt.ship_address = Address.build(refund['shipping_address'])
          refund_receipt.bill_address = Address.build(refund['billing_address'])
          refund_receipt.bill_email = refund['email']
          refund_receipt.txn_date = refund['placed_on']
          refund_receipt.balance = refund['balance']
          
          refund_receipt.ship_date = refund['ship_date'] if refund['ship_date']
          refund_receipt.po_number = refund['po_number'] if refund['po_number']
          refund_receipt.txn_tax_detail = refund['txn_tax_detail'] if refund['txn_tax_detail']
          refund_receipt.tracking_num = refund['tracking_num'] if refund['tracking_num']
          refund_receipt.customer_memo = refund['customer_memo'] if refund['customer_memo']
          refund_receipt.private_note = refund['private_note'] if refund['private_note']
          refund_receipt.apply_tax_after_discount? = refund['apply_tax_after_discount?'] if refund['apply_tax_after_discount?']
          refund_receipt.print_status = refund['print_status'] if refund['print_status']
          refund_receipt.exchange_rate = refund['exchange_rate'] if refund['exchange_rate']
          refund_receipt.payment_ref_number = payment_ref_number if payment_ref_number

          refund_receipt.customer_id = @customer_service.find_or_create.id
          refund_receipt.payment_method_id = @payment_method_service.matching_payment.id
          refund_receipt.deposit_to_account_id = @account_service.find_by_name(deposit_to_account_name).id

          
          if quickbooks_department
            qbo_dept = Department.new(config).find_department(quickbooks_department)
            raise "No Department found in QuickBooks Online with the ID or Name: #{quickbooks_department}" unless qbo_dept
            refund_receipt.department_id = qbo_dept.id
          end

          if quickbooks_shipping_method
            qbo_ship_method = ShipMethod.new(config).find_ship_method(quickbooks_shipping_method)
            raise "No Shipping Method found in QuickBooks Online with the ID or Name: #{quickbooks_shipping_method}" unless qbo_ship_method
            refund_receipt.ship_method_id = qbo_ship_method.id
          end

          if quickbooks_currency
            qbo_currency = Currency.new(config).find_currency(quickbooks_currency)
            raise "No Currency found in QuickBooks Online with the ID or Name: #{quickbooks_currency}" unless qbo_currency
            refund_receipt.currency_id = qbo_currency.id
          end

          if quickbooks_class
            qbo_class = Class.new(config).find_class(quickbooks_class)
            raise "No Class found in QuickBooks Online with the ID or Name: #{quickbooks_class}" unless qbo_class
            refund_receipt.class_id = qbo_class.id
          end

          refund_receipt.line_items = refund['line_items'].to_a.map do|line|
            @line_service.build_refund_receipt_line(line)
          end
          linked_transactions
          custom_fields
          
          

          sales_receipt.line_items = line_service.build_lines(income_account)
        end

        def shipments_tracking_number
          order[:shipments].map do |shipment|
            shipment[:tracking]
          end
        end

        def deposit_to_account_name
          name = refund['deposit_to_account_name'] || config['deposit_to_account_name']
          raise "No Deposit to Account name given. Please add deposit_to_account_name parameter to workflow" unless name

          name
        end

        def quickbooks_department
          refund['quickbooks_department_id'] || config['quickbooks_department_id'] ||
          refund['quickbooks_department_name'] || config['quickbooks_department_name'] ||
          nil
        end

        def quickbooks_shipping_method
          refund['quickbooks_shipping_method_id'] || config['quickbooks_shipping_method_id'] ||
          refund['quickbooks_shipping_method_name'] || config['quickbooks_shipping_method_name'] ||
          nil
        end

        def quickbooks_currency
          refund['quickbooks_currency_id'] || config['quickbooks_currency_id'] ||
          refund['quickbooks_currency_name'] || config['quickbooks_currency_name'] ||
          nil
        end

        def quickbooks_class
          refund['quickbooks_class_id'] || config['quickbooks_class_id'] ||
          refund['quickbooks_class_name'] || config['quickbooks_class_name'] ||
          nil
        end

        def payment_ref_number
          num = nil
          if !refund['payment'].nil?
            num = refund['payment']['id'] || 
                        refund['payment']['number'] || 
                        refund['payment']['reference_number'] || 
                        refund['payment']['qbo_id']
          end

          refund['quickbooks_payment_ref_number'] || config['quickbooks_payment_ref_number'] || num || nil
        end
    end
  end
end
