module Quickbooks
  module Online
    class Client < Quickbooks::Base

      def status_service
        not_supported!
      end

      def sales_receipt
        receipt = create_model("SalesReceipt")
        receipt.header = build_receipt_header
        receipt.doc_number = @order["number"]

        line_items = []

        @order["line_items"].each do |line_item|
          sales_receipt_line_item = Quickeebooks::Windows::Model::SalesReceiptLineItem.new

          sku = line_item["sku"]
          desc = line_item["name"]
          price = line_item["price"]

          item = create_item(sku,desc,price)
          quantity = line_item["quantity"]
          sales_receipt_line_item.quantity = quantity
          sales_receipt_line_item.unit_price  = price
          sales_receipt_line_item.item_id  = item.id
          line_items << sales_receipt_line_item
        end
        receipt.line_items = line_items
        receipt
      end

      def find_account_by_name(account_name)
        list = account_service.list(["NAME :EQUALS: #{account_name}"],1,1)
        if list.count == 0
          raise Exception.new("No Account '#{account_name}' defined in Quickbooks")
        end
        list.entries.first
      end

      def find_item_by_sku(sku)
        list = item_service.list(["NAME :EQUALS: #{sku}"],1,1)
        list.entries.first
      end

      def create_item(sku, desc, price)
        account = find_account_by_name(lookup_value!(@config,"quickbooks.account_name",false,"Sales"))
        item = find_item_by_sku(sku)
        return item if item

        item = create_model("Item")
        item.name = sku
        item.desc = desc
        item.unit_price = Quickeebooks::Windows::Model::Price.new(price)
        item.account_reference = account
        item.taxable = "true"
        return item_service.create(item)
      end

      def find_customer_by_name(name)
        list = customer_service.list(["NAME :EQUALS: #{name}"]).entries
        list.entries.first
      end

      def create_customer(name)
        customer = create_model("Customer")
        customer.name = name
        return customer_service.create(customer)
      end

      def persist
        begin
          receipt = receipt_service.create(sales_receipt)
          @id = receipt.success.object_ref.id.value
          @idDomain = receipt.success.object_ref.id.idDomain
          xref = CrossReference.new
          xref.add(@order["number"], @id, @idDomain)
        rescue Exception
          return 500, {
            'message_id' => @message_id,
            'parameters' => @config,
            'payload' => @payload,
            'error' => exception.message,
            'backtrace' => exception.backtrace
           }
        end

        return 200, {
          'message_id' => @message_id,
          'notifications' => [
            {
              "level" => "info",
              "subject" => "persisted order #{@order["number"]} in Quickbooks",
              "description" => "Quickbooks SalesReceipt id = #{@id} and idDomain = #{@idDomain}"
            }
          ]
        }
      end
    end
  end
end