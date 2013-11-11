class OrderUpdater < Client

  attr_accessor :order

  def initialize(payload, message_id, config={})
    super
    @payload = payload
    @message_id = message_id
    @config = config
    @order = payload['order']['current'] || payload['order']['actual']
    @previous = payload['previous']
  end

  def consume
    response = update_in_quickbooks
    response.to_hash
  end

  private


  def quickbooks_address(address)
      a = Quickeebooks::Windows::Model::Address.new
      a.line1   = address["address1"]
      a.line2   = address["address2"]
      a.city    = address["city"]
      a.country = address["country"]["name"]
      a.country_sub_division_code = address["state_name"]
      if address["state"]
        a.country_sub_division_code ||= address["state"]["name"]
      end

      a.postal_code = address["zipcode"]
      return a
  end

  def update_in_quickbooks
    raise "Total Fail <0" if @order['total'].to_f < 0
    raise "No Web Order Customer Defined in Quickbooks" unless quickbooks_customers.include?("Web Order")

    xref = CrossReference.new
    reference = xref.lookup(@order['number'])
    if reference.nil?
       order_import = OrderImporter.new(@payload, @message_id, @config)
       result = order_import.consume
    end
    return result if reference.nil?

    h = Quickeebooks::Windows::Model::SalesReceiptHeader.new
    h.doc_number = @order['number']
    payment_name = "None"
    if flatten_child_nodes(@order, 'credit_card').present?
      payment_name = flatten_child_nodes(@order, 'credit_card').first["cc_type"] 
    elsif flatten_child_nodes(@order, 'payment').present?
      payment_name = flatten_child_nodes(@order, 'payment').first['payment_method']['name']
    end
    h.deposit_to_account_name = deposit_to_account_name(payment_name)

    h.class_name = @order["customer_type"]

    create_account(h.deposit_to_account_name)

    h.total_amount = @order['total']
    h.txn_date = Time.parse(@order['completed_at']).in_time_zone("EST").strftime("%Y-%m-%d")
    h.customer_name = "Web Order"
    h.shipping_address = quickbooks_address(@order["ship_address"])
    h.note = [@order["bill_address"]["firstname"],@order["bill_address"]["lastname"]].join(" ")
    h.ship_method_name = ship_method_name(flatten_child_nodes(@order, "shipment").first["shipping_method"]["name"])

    raise "No Shipping Method Defined in Quickbooks #{h.ship_method_name}" unless ship_method_service.list.entries.collect(&:name).include?(h.ship_method_name)

    r = receipt_service.fetch_by_id(reference[:id], reference[:id_domain])

     return { 'message_id' => @message_id } if r.nil?
     return { 'message_id' => @message_id } unless r.synchronized == "true"

    r.line_items = flatten_child_nodes(@order, 'line_item').collect do |line_item|
      create_item(line_item["variant"]["sku"], line_item["variant"]["name"],line_item["variant"]["price"],line_item["variant"]["cost_price"], line_item["variant"]["count_on_hand"])
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
    
    adjustments = Adjustment.new(flatten_child_nodes(@order, 'adjustment'))

    if adjustments.shipping.any?
      adjustments.shipping.each do |a|
        l = Quickeebooks::Windows::Model::SalesReceiptLineItem.new
        l.quantity = 1
        l.unit_price  = a['amount']
        l.item_name = "Shipping Charges"
        i = create_item("Shipping Charges", "Shipping Charges", 0, 0, 0, "Other Charge")
        r.line_items << l
      end
    end

    if adjustments.tax.any?
      adjustments.tax.each do |a|
        l = Quickeebooks::Windows::Model::SalesReceiptLineItem.new
        l.quantity = 1
        l.unit_price  = a['amount']
        l.item_name = "Sales Tax"
        create_item( "Sales Tax", "Shipping Charges", 0, 0, 0, "Other Charge")
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
    p r.inspect
    o = receipt_service.update(r)

    @id = o.success.object_ref.id.value
    @idDomain = o.success.object_ref.id.idDomain

    {
      'message_id' => @message_id,
      "delay" => 6000,
      "update_url" => "/status/#{@idDomain}/#{@id}",
      "owner" => "Quickbooks::OrderUpdater"
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
      a.type = "AccountsReceivable"
      #a.sub_type = "Income"
      a.active = true
      account_service.create(a)
    rescue IntuitRequestException
      return "Account already exists"
    end
  end
end
