module QBIntegration
  module Processor
    class Invoice
      include Helper
      attr_reader :invoice

      def initialize(invoice)
        @invoice = invoice
      end

      def as_flowlink_hash
        {
          id: invoice.doc_number,
          q_id: invoice.id,
          due_date: invoice.due_date,
          created_at: invoice.meta_data['create_time'],
          customer_memo: invoice.customer_memo,
          ship_date: invoice.ship_date,
          tracking_num: invoice.tracking_num,
          total: invoice.total.to_f,
          home_total: invoice.home_total.to_f,
          auto_doc_number: invoice.auto_doc_number,
          doc_number: invoice.doc_number,
          txn_date: invoice.txn_date,
          apply_tax_after_discount: invoice.apply_tax_after_discount?,
          print_status: invoice.print_status,
          email_status: invoice.email_status,
          balance: invoice.balance.to_f,
          home_balance: invoice.home_balance.to_f,
          deposit: invoice.deposit.to_f,
          allow_ipn_payment: invoice.allow_ipn_payment?,
          delivery_info: build_delivery_info,
          allow_online_payment: invoice.allow_online_payment?,
          allow_online_credit_card_payment: invoice.allow_online_credit_card_payment?,
          allow_online_ach_payment: invoice.allow_online_ach_payment?,
          exchange_rate: invoice.exchange_rate.to_f,
          private_note: invoice.private_note,
          global_tax_calculation: invoice.global_tax_calculation,
          sync_token: invoice.sync_token,
          billing_address: build_address(invoice.billing_address),
          shipping_address: build_address(invoice.shipping_address),
          email: build_email,
          customer: build_ref(invoice.customer_ref),
          class: build_ref(invoice.class_ref),
          department: build_ref(invoice.department_ref),
          currency: build_ref(invoice.currency_ref),
          sales_term: build_ref(invoice.sales_term_ref),
          deposit_to_account: build_ref(invoice.deposit_to_account_ref),
          ship_method: build_ref(invoice.ship_method_ref),
          ar_account: build_ref(invoice.ar_account_ref),
          tax_detail: build_tax_detail(invoice.txn_tax_detail),
          linked_transactions: build_linked_transactions(invoice.linked_transactions),
          custom_fields: build_custom_fields(invoice.custom_fields),
          line_items: build_line_items(invoice.line_items),
          status: determine_status
        }
      end

      private

      def build_delivery_info
        return unless invoice.delivery_info
        {
          delivery_type: invoice.delivery_info.delivery_type,
          delivery_time: invoice.delivery_info.delivery_time
        }
      end

      def build_line_items(items)
        items.to_a.map do |item|
          Processor::InvoiceLine.new(item).as_flowlink_hash
        end
      end
  
      def build_email
        invoice.bill_email ? invoice.bill_email.address : ''
      end
      
      def build_tax_detail(tax)
        return {} unless tax
        {
          txn_tax_code_ref: tax["txn_tax_code_ref"] ? tax["txn_tax_code_ref"]['value'] : nil,
          total_tax: tax["total_tax"],
          tax_lines: tax_lines(tax.lines)
        }
      end
  
      def tax_lines(lines)
        lines.to_a.map do |line|
          {
            type: line["DetailType"],
            amount: line["Amount"],
            line_detail: line["TaxLineDetail"]
          }
        end
      end
  
      def build_linked_transactions(txns)
        txns.to_a.map do |txn|
            {
              transaction_id: txn["TxnId"],
              transaction_type: ["TxnType"]
            }
        end
      end

      def build_custom_fields(fields)
        fields.to_a.map do |cf|
          {
            id: cf.id,
            name: cf.name,
            type: cf.type,
            string_value: cf.string_value,
            boolean_value: cf.boolean_value,
            date_value: cf.date_value,
            number_value: cf.number_value
          }
        end
      end

      # QuickBooks API doesn't provide status so we build the logic to determine status here
      
      # Paid
      # Partial
      # Partial Sent - Is this a status?
      # Open
      # Open Sent - Is this a status?
      # Overdue
      # Overdue Sent - Is this a status?
      # Overdue Viewed, Open Viewed, Partial Viewed  <-- Are these statuses?
      def determine_status
        sent = invoice.email_status == "EmailSent"
        balance = invoice.balance.to_f

        if balance == 0
          "Paid"
        elsif check_due_date(invoice.due_date)
          sent ? "Overdue Sent" : "Overdue"
        elsif balance > 0 && balance < invoice.total
          sent ? "Partial Sent" : "Partial"
        elsif balance == invoice.total
          sent ? "Open Sent" : "Open"
        end
      end

      def check_due_date(due)
        a = due.to_s.split('-')
        big_now = Time.now.utc

        Time.new(a[0], a[1], a[2]) < Time.new(big_now.year, big_now.month, big_now.day)
      end

    end
  end
end
