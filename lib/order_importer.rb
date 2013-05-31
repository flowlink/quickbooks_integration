class OrderImporter < Client
  attr_accessor :order

  def consume
    response = import_to_quickbooks
    response.to_hash
  end

  private

  def quickbooks_address(address)
      a = Quickeebooks::Windows::Model::Address.new
      a.line1   = [address["firstname"], address["lastname"]].join(" ")
      a.line2   = address["address1"]
      a.line3   = address["address2"]
      a.city    = address["city"]
      a.country = address["country"]["name"]
      a.country_sub_division_code = address["state_name"] 
      a.country_sub_division_code ||= address["state"]["name"] if address["state"]
      a.postal_code = address["zipcode"]
      return a
    end

  def import_to_quickbooks
    raise "Total Fail <0" if @order['total'].to_f < 0
    raise "No Web Order Customer Defined in Quickbooks" unless quickbooks_customers.include?("Web Order")

    h = Quickeebooks::Windows::Model::SalesReceiptHeader.new
    h.doc_number = @order['number']
    payment_name = "None"

    if flatten_child_nodes(@order, "credit_card").first.present?
      payment_name = flatten_child_nodes(@order, "credit_card").first["cc_type"]
    elsif flatten_child_nodes(@order, "payment").first.present?
      payment_name = flatten_child_nodes(@order, "payment").first["payment_method"]["name"]
    end
    h.deposit_to_account_name = deposit_to_account_name(payment_name)

    h.class_name = "WEB"

    create_account(h.deposit_to_account_name)

    h.total_amount = @order['total']
    h.txn_date = Time.parse(@order['completed_at']).in_time_zone("EST").strftime("%Y-%m-%d")
    h.customer_name = "Web Order"
    h.shipping_address = quickbooks_address(@order["ship_address"])
    h.note = [@order["bill_address"]["firstname"],@order["bill_address"]["lastname"]].join(" ")
    h.ship_method_name = ship_method_name(flatten_child_nodes(@order, "shipment").first["shipping_method"]["name"]) 

    raise "No Shipping Method Defined in Quickbooks #{h.ship_method_name}" unless ship_method_service.list.entries.collect(&:name).include?(h.ship_method_name)
    h.payment_method_name = payment_method_name(payment_name)
    raise "No Payment Method Defined in Quickbooks #{h.payment_method_name}" unless payment_methods.include?(h.payment_method_name)

    r = Quickeebooks::Windows::Model::SalesReceipt.new
    r.line_items = flatten_child_nodes(@order, 'line_item').collect do |line_item|
      l = Quickeebooks::Windows::Model::SalesReceiptLineItem.new
      l.quantity = line_item["quantity"]
      l.unit_price  = line_item["price"]
      if item_exists?(line_item["variant"]["sku"])
        l.item_name = line_item["variant"]["sku"]
      else
        l.item_name = "New-001"
        l.desc = "#{line_item["variant"]["sku"]} - #{line_item["variant"]["name"]}"
      end
      l
    end

    adjustments = Adjustment.new(flatten_child_nodes(@order,'adjustment'))
    if adjustments.shipping.any?
      adjustments.shipping.each do |a|
        l = Quickeebooks::Windows::Model::SalesReceiptLineItem.new
        l.quantity = 1
        l.unit_price  = a['amount']
        l.item_name = "Shipping Charges"
        create_item("Shipping Charges", "Shipping Charges", 0, 0, 0, "Other Charge")
        r.line_items << l
      end
    end

    if adjustments.tax.any?
      adjustments.tax.each do |a|
        l = Quickeebooks::Windows::Model::SalesReceiptLineItem.new
        l.amount  = a['amount']
        l.item_name = "State Sales Tax-NY"
        create_item( "State Sales Tax-NY", "Shipping Charges", 0, 0, 0, "Other Charge")
        r.line_items << l
      end
    end

    if adjustments.coupon.any?
      adjustments.coupon.each do |a|
        create_item("Coupons", "Coupons", 0,0,0, "Other Charge")
        l = Quickeebooks::Windows::Model::SalesReceiptLineItem.new
        l.unit_price  = a['amount']
        l.item_name = "Coupons"
        r.line_items << l
      end
    end

    if adjustments.discount.any?
      create_item("Discount", "Added Discount", 0,0,0, "Other Charge")
      adjustments.discount.each do |a|
        l = Quickeebooks::Windows::Model::SalesReceiptLineItem.new
        l.unit_price  = a['amount']
        l.item_name = "Discount"
        r.line_items << l
      end
    end

    r.header = h

    o = receipt_service.create(r)
    @id = o.success.object_ref.id.value
    @idDomain = o.success.object_ref.id.idDomain

    {
      'message_id' => @payload['message_id'],
      'result' => :success,
      'code' => 200,
      "delay" => 6000,
      "update_url" => "http://localhost:3000/status/#{@idDomain}/#{@id}",
      "owner" => "Quickbooks::OrderImporter"
    }
  end

  def create_item(sku, desc, price, cost_price, count_on_hand, product_type="Product")
    return "Item already exists" if item_service.list.entries.collect(&:name).include?(sku)
    begin
      i = Quickeebooks::Windows::Model::Item.new
      i.name = sku
      i.desc = desc
      i.unit_price = Quickeebooks::Windows::Model::Price.new(price)
      i.type = product_type

      raise "No Account Defined in Quickbooks" unless account_service.list.entries.collect(&:name).include?("Sales")
      i.account_reference = Quickeebooks::Windows::Model::AccountReference.new(nil, "Sales")
      i.expense_account_reference = Quickeebooks::Windows::Model::AccountReference.new(nil, "Sales")
      i.cogs_account_reference = Quickeebooks::Windows::Model::AccountReference.new(nil, "Sales")
      i.taxable = "true"
      i.man_part_num = sku
      i.purchase_cost = Quickeebooks::Windows::Model::Price.new(cost_price)
      i.qty_on_hand = count_on_hand
      return item_service.create(i)
    rescue IntuitRequestException
      return "Error Creating Item"
    end
  end

  def create_account(name)
    begin
      a = Quickeebooks::Windows::Model::Account.new
      a.name = name
      a.type = "Other Current Asset"
      #a.sub_type = "Income"
      a.active = true
      account_service.create(a)
    rescue IntuitRequestException
      return "Account already exists"
    end
  end
end
