module QBIntegration
  module Processor
    class SalesReceipt
      include Helper
      attr_reader :sales_receipt, :config

      def initialize(sales_receipt, config)
        @sales_receipt = sales_receipt
        @config = config
        @sales_line_details = select_sales_lines
        @item_lines = select_item_lines

        @group_line_details = select_group_lines
      end

      def as_flowlink_hash
        {
          id: sales_receipt.id,
          name: doc_number,
          number: doc_number,
          created_at: sales_receipt.txn_date,
          line_items: format_line_items,
          group_line_items: format_group_line_items,
          placed_on: sales_receipt.meta_data["create_time"],
          updated_at: sales_receipt.meta_data["last_updated_time"],
          totals: {
            tax: tax,
            shipping: shipping,
            discount: discount,
            item: item,
            order: sprintf('%.2f', sales_receipt.total)
          },
          shipping_address: Processor::Address.new(sales_receipt.ship_address).as_flowlink_hash,
          billing_address: Processor::Address.new(sales_receipt.bill_address).as_flowlink_hash,
          global_tax_calculation: sales_receipt.global_tax_calculation,
          po_number: sales_receipt.po_number,
          ship_date: sales_receipt.ship_date,
          tracking_num: sales_receipt.tracking_num,
          payment_ref_number: sales_receipt.payment_ref_number,
          delivery_info: sales_receipt.delivery_info,
          customer_memo: sales_receipt.customer_memo,
          private_note: sales_receipt.private_note,
          apply_tax_after_discount: sales_receipt.apply_tax_after_discount?,
          print_status: sales_receipt.print_status,
          balance: sales_receipt.balance,
          email_status: sales_receipt.email_status,
          exchange_rate: sales_receipt.exchange_rate,
          total: sales_receipt.total,
          home_total: sales_receipt.home_total,
          email: sales_receipt.bill_email && sales_receipt.bill_email.address,
          ship_method: sales_receipt.ship_method_ref && sales_receipt.ship_method_ref.value,
          qbo_ship_method_ref: sales_receipt.ship_method_ref,
          currency: sales_receipt.currency_ref && sales_receipt.currency_ref.value,
          qbo_currency_ref: sales_receipt.currency_ref,
          payment_method: sales_receipt.payment_method_ref && sales_receipt.payment_method_ref.value,
          qbo_payment_method_ref: sales_receipt.payment_method_ref,
          customer_name: sales_receipt.customer_ref && sales_receipt.customer_ref.value,
          qbo_customer_ref: sales_receipt.customer_ref,
          department: sales_receipt.department_ref && sales_receipt.department_ref.value,
          qbo_department_ref: sales_receipt.department_ref,
          deposit_to_account: sales_receipt.deposit_to_account_ref && sales_receipt.deposit_to_account_ref.value,
          qbo_deposit_to_account_ref: sales_receipt.deposit_to_account_ref,
          class: sales_receipt.class_ref && sales_receipt.class_ref.value,
          qbo_class_ref: sales_receipt.class_ref,
          custom_fields: custom_fields,
          tax_information: tax_information
        }
      end

      private

      def doc_number
        if config['quickbooks_prefix'].nil?
          sales_receipt.doc_number
        else
          match_prefix ? sales_receipt.doc_number.sub(config['quickbooks_prefix'], "") : sales_receipt.doc_number
        end
      end

      def match_prefix
        prefix = Regexp.new("^" + config['quickbooks_prefix'])
        sales_receipt.doc_number.match(prefix)
      end

      def format_line_items
        @item_lines.map do |line_item|
          {
            id: line_item.sales_item_line_detail["item_ref"]["value"],
            name: line_item.sales_item_line_detail["item_ref"]["name"],
            description: line_item.description,
            amount: sprintf('%.2f', line_item.amount),
            price: line_item.sales_item_line_detail["unit_price"].truncate(2).to_s('F'),
            quantity: line_item.sales_item_line_detail["quantity"].to_i
          }
        end
      end

      def format_group_line_items
        @group_line_details.map do |line_item|
          {
            id: line_item.group_line_detail["group_item_ref"]["value"],
            name: line_item.group_line_detail["group_item_ref"]["name"],
            description: line_item.description,
            amount: sprintf('%.2f', (line_item.amount || 0)),
            quantity: line_item.group_line_detail["quantity"].to_i,
            child_items: group_child_items(line_item.group_line_detail["line_items"])
          }
        end
      end

      def tax
        tax_line = filter_line(/tax/)
        return 0 unless tax_line
        sprintf('%.2f',tax_line.amount)
      end

      def shipping
        shipping_line = filter_line(/shipping/)
        return 0 unless shipping_line
        sprintf('%.2f',shipping_line.amount)
      end

      def discount
        discount_line = filter_line(/discount/)
        return 0 unless discount_line
        sprintf('%.2f',discount_line.amount)
      end

      def item
        number = @item_lines.reduce(0) { |sum, line_details| sum + line_details.amount }
        sprintf('%.2f', number)
      end

      def filter_line(matching)
        @sales_line_details.select { |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(matching) }.first
      end

      def select_sales_lines
        @sales_receipt.line_items.select { |line| line.detail_type.to_s == "SalesItemLineDetail" }
      end

      def select_group_lines
        @sales_receipt.line_items.select { |line| line.detail_type.to_s == "GroupLineDetail" }
      end

      def select_item_lines
        reject_items = /shipping|tax|discount/
        @sales_line_details.reject{ |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(reject_items) }
      end

      def custom_fields
        return [] unless sales_receipt.custom_fields && !sales_receipt.custom_fields.empty?

        sales_receipt.custom_fields.map do |field|
          {
            name: field.name,
            type: field.type,
            string_value: field.string_value,
            boolean_value: field.boolean_value,
            date_value: field.date_value,
            number_value: field.number_value
          }
        end
      end

      def tax_information
        return unless sales_receipt.txn_tax_detail

        {
          txn_tax_code: sales_receipt.txn_tax_detail.txn_tax_code_ref && sales_receipt.txn_tax_detail.txn_tax_code_ref.value,
          qbo_txn_tax_code_ref: sales_receipt.txn_tax_detail.txn_tax_code_ref,
          total_tax: sprintf('%.2f', sales_receipt.txn_tax_detail.total_tax),
          tax_lines: sales_receipt.txn_tax_detail.lines.map do |line|
            {
              line_num: line.line_num,
              description: line.description,
              amount: line.amount,
              detail_type: line.detail_type,
              tax_line_detail: line.tax_line_detail
            }
          end
        }
      end

      def group_child_items(line_items)
        line_items.map do |line|
          {
            line_num: line.line_num,
            description: line.description,
            amount: sprintf('%.2f', line.amount),
            detail_type: line.detail_type,
            sales_item_line_detail: {
              id: line.sales_item_line_detail["item_ref"]["value"],
              name: line.sales_item_line_detail["item_ref"]["name"],
              quantity: sprintf('%.2f', line.sales_item_line_detail["quantity"]),
              price: line.sales_item_line_detail["unit_price"].truncate(2).to_s('F'),
              item: line.sales_item_line_detail['item_ref'] && line.sales_item_line_detail['item_ref']['value'],
              qbo_item_ref: line.sales_item_line_detail['item_ref'],
              class: line.sales_item_line_detail['class_ref'] && line.sales_item_line_detail['class_ref']['value'],
              qbo_class_ref: line.sales_item_line_detail['class_ref'],
              price_level: line.sales_item_line_detail['price_level_ref'] && line.sales_item_line_detail['price_level_ref']['value'],
              qbo_price_level_ref: line.sales_item_line_detail['price_level_ref'],
              tax_code: line.sales_item_line_detail['tax_code_ref'] && line.sales_item_line_detail['tax_code_ref']['value'],
              qbo_tax_code_ref: line.sales_item_line_detail['tax_code_ref'],
              rate_percent: line.sales_item_line_detail['rate_percent'],
              service_date: line.sales_item_line_detail['service_date']
            },
            sub_total_line_detail: line.sub_total_line_detail,
            payment_line_detail: line.payment_line_detail,
            discount_line_detail: line.discount_line_detail,
            journal_entry_line_detail: line.journal_entry_line_detail,
            group_line_detail: line.group_line_detail
          }
        end
      end
    end
  end
end
