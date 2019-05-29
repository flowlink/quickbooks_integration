module QBIntegration
  module Processor
    class SalesReceipt
      include Helper
      attr_reader :sales_receipt

      def initialize(sales_receipt)
        @sales_receipt = sales_receipt
      end

      def as_flowlink_hash
        {
          id: sales_receipt.id,
          name: sales_receipt.doc_number,
          number: sales_receipt.doc_number,
          created_at: sales_receipt.txn_date,
          line_items: format_line_items(sales_receipt.line_items),
          currency: sales_receipt.currency_ref.value,
          placed_on: sales_receipt.meta_data["create_time"],
          updated_at: sales_receipt.meta_data["last_updated_time"],
          totals: format_total(sales_receipt.line_items),
          shipping_address: Processor::Address.new(sales_receipt.ship_address).as_flowlink_hash,
          billing_address: Processor::Address.new(sales_receipt.bill_address).as_flowlink_hash
        }
      end

      private

      def format_total(line_items)
        sales_line_details = line_items.select { |line| line.detail_type.to_s == "SalesItemLineDetail" }

        tax_line = sales_line_details.select { |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(/tax/) }.first
        shipping_line = sales_line_details.select { |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(/shipping/) }.first
        discount_line = sales_line_details.select { |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(/discount/) }.first

        tax = tax_line && tax_line.amount || BigDecimal("0")
        shipping = shipping_line && shipping_line.amount || BigDecimal("0")
        discount = discount_line && discount_line.amount || BigDecimal("0")
        item = sales_line_details.reduce(0) { |sum, line_details| sum + line_details.amount }.truncate(2).to_s("F").to_f

        {
          tax: tax,
          shipping: shipping,
          discount: discount,
          item: item.to_s,
          order: "%.2f" % BigDecimal(tax + shipping + discount + item).truncate(2)
        }
      end

      def format_line_items(line_items)
        reject_items = /shipping|tax|discount/
        sales_line_details = line_items.select { |line| line.detail_type.to_s == "SalesItemLineDetail" }
        filtered_line_items = sales_line_details.reject{ |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(reject_items) }
        filtered_line_items.map do |line_item|
          {
            id: line_item.sales_item_line_detail["item_ref"]["value"],
            name: line_item.sales_item_line_detail["item_ref"]["name"],
            description: line_item.description,
            price: line_item.sales_item_line_detail["unit_price"].truncate(2).to_s('F'),
            quantity: line_item.sales_item_line_detail["quantity"].to_i
          }
        end
      end

    end
  end
end
