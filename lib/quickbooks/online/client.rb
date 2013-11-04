module Quickbooks
  module Online
    class Client < Quickbooks::Base

      def status_service
        not_supported!
      end

      def build_receipt_header
        receipt_header = super
        customer_name = "#{@order["billing_address"]["firstname"]} #{@order["billing_address"]["lastname"]}"
        customer = find_customer_by_name(customer_name)
        unless customer
         customer = create_customer
        end
        receipt_header.customer_id = customer.id

        receipt_header.payment_method_id = find_payment_method_by_name(payment_method(payment_method_name)).id
        receipt_header
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
          sales_receipt_line_item.amount = (quantity * price)
          sales_receipt_line_item.desc = line_item["name"]
          line_items << sales_receipt_line_item
        end

        adjustments = Adjustment.new(@original["adjustments"])

        adjustments.shipping.each do |adjustment|
          sku = get_config!("quickbooks.shipping_item")
          line = adjustment_to_line(adjustment,sku)
          line_items << line
        end

        adjustments.tax.each do |adjustment|
          sku = get_config!("quickbooks.tax_item")
          line = adjustment_to_line(adjustment,sku)
          line_items << line
        end

        adjustments.coupon.each do |adjustment|
          sku = get_config!("quickbooks.coupon_item")
          line = adjustment_to_line(adjustment,sku)
          line_items << line
        end

        adjustments.discount.each do |adjustment|
          sku = get_config!("quickbooks.discount_item")
          line = adjustment_to_line(adjustment,sku)
          line_items << line
        end

        # TODO
        # adjustment.manual_charge.each do |adjustment|
        #   sku = get_config!("quickbooks.manual_charge_item")
        #   line = adjustment_to_line(adjustment,sku)
        #   line_items << line
        # end

        receipt.line_items = line_items
        receipt
      end

      def adjustment_to_line(adjustment, adjustment_sku)
        line = Quickeebooks::Windows::Model::SalesReceiptLineItem.new
        sku = adjustment_sku
        desc = adjustment["label"]
        price = adjustment["amount"]
        item = create_item(sku,desc,price)

        line.quantity = 1
        line.unit_price = price
        line.amount = price
        line.desc = desc
        line.item_id = item.id

        line
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

      def find_payment_method_by_name(name)
        list = payment_method_service.list(["NAME :EQUALS: #{name}"]).entries
        if list.count == 0
          raise Exception.new("No PaymentMethod '#{name}' defined in Quickbooks")
        end
        list.entries.first
      end

      def create_customer
        customer = create_model("Customer")

        customer_name = "#{@order["billing_address"]["firstname"]} #{@order["billing_address"]["lastname"]}"

        billing_address = quickbook_address(@order["billing_address"])
        billing_address.tag = "Billing"
        customer.address = billing_address

        shipping_address = quickbook_address(@order["shipping_address"])
        shipping_address.tag = "Shipping"
        #quickeebooks will append the addresses to the internal addresses var.
        customer.address = shipping_address
        customer.name = customer_name

        customer.email_address = @order["email"]

        return customer_service.create(customer)
      end

      def persist
        super
        case @message_name
          when "order:new"
            receipt = receipt_service.create(sales_receipt)
            id = receipt.id.value
            idDomain = receipt.id.idDomain
            cross_ref_hash = @xref.add(@order["number"], id, idDomain)
          when "order:updated"
            order_number = @order["number"]
            cross_ref_hash = @xref.lookup(order_number)
            current_receipt = receipt_service.fetch_by_id(cross_ref_hash[:id])
            receipt = sales_receipt
            receipt.id = Quickeebooks::Online::Model::Id.new(cross_ref_hash[:id])
            receipt.sync_token = current_receipt.sync_token
            receipt = receipt_service.update(receipt)
          else
            raise Exception.new("received unsupported message #{@message_name}, either use 'order:new' or 'order:updated'")
        end
        {
          "receipt" => receipt,
          "xref" => cross_ref_hash
        }
      end
    end
  end
end