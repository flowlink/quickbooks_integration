module QBIntegration
  class SalesReceipt < Base
    attr_accessor :order, :xref

    def initialize(message = {}, config)
      super

      @order = payload['order']
      @xref = CrossReference.new
    end

    # TODO legacy not sure we still need this header key in sales receipt
    def build_receipt_header
      receipt_header = create_model("SalesReceiptHeader")
      receipt_header.doc_number = @order['number']
      receipt_header.total_amount = @order['totals']['order']
      timezone = get_config!("quickbooks.timezone")

      utc_time = Time.parse(@order["placed_on"])
      tz = TZInfo::Timezone.get(timezone)

      txn_date = Quickeebooks::Common::DateTime.new
      txn_date.value = tz.utc_to_local(utc_time).to_s
      receipt_header.txn_date = txn_date
      receipt_header.shipping_address = quickbook_address(@order["shipping_address"])

      receipt_header.ship_method_name = @order["shipments"].first["shipping_method"]

      receipt_header.payment_method_name = payment_method(payment_method_name)

      customer_name = "#{@order["billing_address"]["firstname"]} #{@order["billing_address"]["lastname"]}"
      customer = find_customer_by_name(customer_name)
      unless customer
       customer = create_customer
      end
      receipt_header.customer_id = customer.id

      receipt_header.payment_method_id = find_payment_method_by_name(payment_method(payment_method_name)).id
      receipt_header.deposit_to_account_id = find_account_by_name(get_config!("quickbooks.deposit_to_account_name")).id

      receipt_header
    end

    def payment_method_name
      if @original.has_key?("credit_cards") && !@original["credit_cards"].empty?
        payment_name = @original["credit_cards"].first["cc_type"]
      end
      unless payment_name
        payment_name = @original["payments"].first["payment_method"]["name"] if @original["payments"]
      end
      payment_name = "None" unless payment_name
      payment_name
    end

    def quickbook_address(order_address)
      address = create_model("Address")
      address.line1   = order_address["address1"]
      address.line2   = order_address["address2"]
      address.city    = order_address["city"]
      address.country = order_address["country"]
      address.country_sub_division_code = order_address["state"]
      address.postal_code = order_address["zipcode"]
      return address
    end

    def ship_method_name(shipping_method)
      ship_method_name_mapping = get_config!("quickbooks.ship_method_name")
      lookup_value!(ship_method_name_mapping.first, shipping_method)
    end

    def payment_method(payment_name)
      payment_method_name_mapping = get_config!("quickbooks.payment_method_name")
      lookup_value!(payment_method_name_mapping.first, payment_name)
    end

    # TODO Understand this xref thing. Not sure we still need it
    def persist
      order_number = @order["number"]
      order_xref = @xref.lookup(order_number)
      case @message_name
      when "order:new"
        if order_xref
          raise AlreadyPersistedOrderException.new(
            "Got 'order:new' message for order #{order_number} that already has a
            sales receipt with id: #{order_xref[:id]} and domain: #{order_xref[:id_domain]}"
          )
        end
      when "order:updated"
        if !order_xref
          raise NoReceiptForOrderException.new("Got 'order:updated' message for order #{order_number} that has not a sales receipt for it yet.")
        end
      end

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
