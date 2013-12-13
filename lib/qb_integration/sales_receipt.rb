module QBIntegration
  class SalesReceipt < Base
    attr_accessor :order, :xref, :sales_receipt

    def initialize(message = {}, config)
      super

      @order = payload['order']
      @sales_receipt = Quickbooks::Model::SalesReceipt.new
    end

    def save
      sales_receipt.doc_number = order["number"]
      sales_receipt.line_items = line_service.build_lines
      sales_receipt.total = @order['totals']['order']

      # TODO check if we still need this timezone conversion thing
      # timezone = get_config!("quickbooks.timezone")
      # utc_time = Time.parse(@order["placed_on"])
      # tz = TZInfo::Timezone.get(timezone)

      # txn_date = Quickeebooks::Common::DateTime.new
      # txn_date.value = tz.utc_to_local(utc_time).to_s
      sales_receipt.placed_on = @order['placed_on']

      sales_receipt.ship_address = Address.build order["shipping_address"]
      sales_receipt.bill_address = Address.build order["billing_address"]

      sales_receipt.payment_method_ref = payment_method_service.matching_payment.id
      sales_receipt.customer_ref = customer_service.find_or_create.id

      # TODO We need a check here. Users might want to just use the default
      # undeposit funds account
      sales_receipt.deposit_to_account_ref = account_service.find_by_name(config.fetch("quickbooks.account_name")).id

      sales_receipt_service.create sales_receipt
    end

    # TODO legacy not sure we still need this header key in sales receipt
    def build_receipt_header
      receipt_header = create_model("SalesReceiptHeader")
      receipt_header.doc_number = @order['number']
      receipt_header.total_amount = @order['totals']['order']

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

    def ship_method_name(shipping_method)
      ship_method_name_mapping = get_config!("quickbooks.ship_method_name")
      lookup_value!(ship_method_name_mapping.first, shipping_method)
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
