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
      end

      def as_flowlink_hash
        {
          id: sales_receipt.id,
          name: doc_number,
          number: doc_number,
          created_at: sales_receipt.txn_date,
          line_items: format_line_items,
          currency: sales_receipt.currency_ref.value,
          placed_on: sales_receipt.meta_data["create_time"],
          updated_at: sales_receipt.meta_data["last_updated_time"],
          totals: {
            tax: tax,
            shipping: shipping,
            discount: discount,
            item: item.to_s,
            order: "%.2f" % BigDecimal(tax + shipping + discount + item).truncate(2)
          },
          shipping_address: Processor::Address.new(sales_receipt.ship_address).as_flowlink_hash,
          billing_address: Processor::Address.new(sales_receipt.bill_address).as_flowlink_hash,
          customer_object: build_ref(sales_receipt.customer_ref),
          relationships: [
            { object: "customer_object", key: "id" }
          ]
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
            price: line_item.sales_item_line_detail["unit_price"].truncate(2).to_s('F'),
            quantity: line_item.sales_item_line_detail["quantity"].to_i
          }
        end
      end

      def tax
        tax_line = filter_line(/tax/)
        tax_line && tax_line.amount || BigDecimal("0")
      end

      def shipping
        shipping_line = filter_line(/shipping/)
        shipping_line && shipping_line.amount || BigDecimal("0")
      end

      def discount
        discount_line = filter_line(/discount/)
        discount_line && discount_line.amount || BigDecimal("0")
      end

      def item
        @sales_line_details.reduce(0) { |sum, line_details| sum + line_details.amount }.truncate(2).to_s("F").to_f
      end

      def filter_line(matching)
        @sales_line_details.select { |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(matching) }.first
      end

      def select_sales_lines
        @sales_receipt.line_items.select { |line| line.detail_type.to_s == "SalesItemLineDetail" }
      end

      def select_item_lines
        reject_items = /shipping|tax|discount/
        @sales_line_details.reject{ |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(reject_items) }
      end

    end
  end
end
