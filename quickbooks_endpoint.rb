require_relative 'lib/qb_integration'

class QuickbooksEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  set :show_exceptions, false

  before do
    Honeybadger.context({
      payload: @payload,
      config: @config
    })
  end

  error do
    result 500, lookup_error_message
  end

  post '/get_tokens' do
    base_service = QBIntegration::Service::Token.new(@config)

    add_parameter 'access_token', base_service.access_token.token
    add_parameter 'refresh_token', base_service.access_token.refresh_token

    result 200, "Tokens successfully retrieved"
  end

  post '/validate_token'do
    token = QBIntegration::Service::Token.new(@config)
    if token.valid?
      result 200
    else
      result 401
    end
  end

  post '/add_product' do
    code, summary = QBIntegration::Product.new(@payload, @config).import

    result code, summary
  end

  post '/update_product' do
    code, summary = QBIntegration::Product.new(@payload, @config).import

    result code, summary
  end

  post '/add_journal' do
    code, summary = QBIntegration::JournalEntry.new(@payload, @config).add

    result code, summary
  end

  post '/update_journal' do
    code, summary = QBIntegration::JournalEntry.new(@payload, @config).update

    result code, summary
  end

  post '/delete_journal' do
    code, summary = QBIntegration::JournalEntry.new(@payload, @config).delete

    result code, summary
  end

  post '/get_orders' do
    orders, summary, new_page_number, since, code = QBIntegration::Order.new(@payload, @config).get
    orders.each do |order|
      add_object :order, order
    end

    result code, summary
  end

  post '/add_order' do
    begin
      code, summary, added_order = QBIntegration::Order.new(@payload, @config).create
      add_object :order, added_order

      result code, summary
    rescue QBIntegration::AlreadyPersistedOrderException => e
      notify_honeybadger e
      result 500, e.message
    end
  end

  post '/add_refund_receipt' do
    begin
      code, summary, added_refund = QBIntegration::RefundReceipt.new(@payload, @config).create

      result code, summary
    rescue QBIntegration::AlreadyPersistedOrderException => e
      result 500, e.message
    end
  end

  post '/add_purchase_order' do
    begin
      code, summary = QBIntegration::PurchaseOrder.new(@payload, @config).create

      result code, summary
    rescue QBIntegration::AlreadyPersistedOrderException => e
      notify_honeybadger e
      result 500, e.message
    end
  end

  post '/update_purchase_order' do
    code, summary = QBIntegration::PurchaseOrder.new(@payload, @config).update

    result code, summary
  end

  ### ACCOUNTTECH SPECIFIC ENDPOINT ###
  # Use the above journal endpoints for general use
  post '/add_journal_entry' do
    if @payload['journal_entry']['action'] == "ADD"
      puts 'ADD'
      code, summary = QBIntegration::JournalEntry.new(@payload, @config).update

    elsif @payload['journal_entry']['action'] == "UPDATE"
      puts 'UPDATE'
      code, summary = QBIntegration::JournalEntry.new(@payload, @config).update

    elsif @payload['journal_entry']['action'] == "DELETE"
      puts 'DELETE'
      code, summary = QBIntegration::JournalEntry.new(@payload, @config).delete

    else
      code = 200
      summary = "No Valid Action Given"
    end

    result code, summary
  end
  # End of Specific Endpoint

  post '/update_order' do
    code, summary, updated_order = QBIntegration::Order.new(@payload, @config).update

    add_object :order, updated_order
    
    result code, summary
  end

  post '/cancel_order' do
    code, summary = QBIntegration::Order.new(@payload, @config).cancel

    result code, summary
  end

  post '/add_invoice' do
    begin
      code, summary = QBIntegration::Invoice.new(@payload, @config).create

      result code, summary
    rescue QBIntegration::AlreadyPersistedInvoiceException => e
      notify_honeybadger e
      result 500, e.message
    end
  end

  post '/update_invoice' do
    code, summary = QBIntegration::Invoice.new(@payload, @config).update

    result code, summary
  end

  post '/get_invoices' do
    qbo_invoice = QBIntegration::Invoice.new(@payload, @config)
    summary, page, since, code = qbo_invoice.get()
  
    qbo_invoice.invoices.each do |invoice|
      add_object :invoice, qbo_invoice.build_invoice(invoice, @config)
    end
    add_parameter 'quickbooks_page_num', page
    add_parameter 'quickbooks_since', since

    result code, summary
  end

  post '/add_return' do
    code, summary = QBIntegration::ReturnAuthorization.new(@payload, @config).create

    result code, summary
  end

  post '/update_return' do
    code, summary = QBIntegration::ReturnAuthorization.new(@payload, @config).update

    result code, summary
  end

  post '/set_inventory' do
    code, summary = QBIntegration::Stock.new(@payload, @config).set

    result code, summary
  end

  post '/get_vendors' do
    now = Time.now.utc.iso8601

    code, vendors = QBIntegration::Vendor.new(@payload, @config).index
    vendors.each { |vendor| add_object :vendor, vendor }

    new_since = code === 200 ? now : @config.fetch("quickbooks_since")
    add_parameter "quickbooks_since", new_since
    
    add_parameter "page", @config.fetch("page", 1)

    result code, "Retrieved #{vendors.size} vendors"
  end

  post '/add_vendor' do
    code, summary, vendor = QBIntegration::Vendor.new(@payload, @config).create

    add_object :vendor, vendor
    result code, summary
  end

  post '/update_vendor' do
    code, summary, vendor = QBIntegration::Vendor.new(@payload, @config).update

    add_object :vendor, vendor
    result code, summary
  end

  post '/get_inventory' do
    stock = QBIntegration::Stock.new(@payload, @config)

    if stock.name.present? && stock.item
      inventory = stock.inventory
      inventory[:key] = @config[:flowlink_data_object_identifier] if @config[:flowlink_data_object_identifier]

      add_object :inventory, stock.inventory

      result 200
    elsif stock.items.present?
      stock.inventories.each do |item|
        item[:key] = @config[:flowlink_data_object_identifier] if @config[:flowlink_data_object_identifier]
        add_object :inventory, item
      end
      add_parameter 'quickbooks_poll_stock_timestamp', stock.last_modified_date

      result 200
    else
      result 200
    end
  end

  post '/get_customers' do
    qbo_customer = QBIntegration::Customer.new(@payload, @config)
    summary, page, since, code = qbo_customer.get()

    qbo_customer.customers.each do |customer|
      add_object :customer, qbo_customer.build_customer(customer)
    end

    add_parameter 'quickbooks_page_num', page
    add_parameter 'quickbooks_since', since
    result code, summary
  end

  post '/add_customer' do
    code, summary, customer = QBIntegration::Customer.new(@payload, @config).create

    add_object :customer, customer
    result code, summary
  end

  post '/update_customer' do
    code, summary, customer = QBIntegration::Customer.new(@payload, @config).update

    add_object :customer, customer
    result code, summary
  end

  post '/get_products' do
    qbo_item = QBIntegration::Item.new(@payload, @config)
    summary, page, since, code = qbo_item.get()

    qbo_item.items.each do |item|
      add_object :product, qbo_item.build_item(item)
    end

    add_parameter 'quickbooks_page_num', page
    add_parameter 'quickbooks_since', since

    result code, summary
  end

  post '/add_payment' do
    code, summary = QBIntegration::Payment.new(@payload, @config).create

    result code, summary
  end

  post '/get_payments' do
    qbo_payment = QBIntegration::Payment.new(@payload, @config)
    summary, page, since, code = qbo_payment.get()

    qbo_payment.new_or_updated_payments.each do |payment|
      add_object :payment, qbo_payment.build_payment(payment)
    end

    add_parameter 'quickbooks_page_num', page
    add_parameter 'quickbooks_since', since
    
    result code, summary
  end

  post '/add_bill_to_purchase_order' do
    code, summary, bill, po = QBIntegration::Bill.new(@payload, @config).create

    add_object :bill, bill
    add_object :purchase_order, po

    result code, summary
  end

  def lookup_error_message
    case env['sinatra.error'].class.to_s
    when "Quickbooks::AuthorizationFailure"
      "Authorization failure. Please check your QuickBooks credentials"
    when "Quickbooks::ServiceUnavailable"
      "QuickBooks API appears to be inaccessible HTTP 503 returned."
    else
      env['sinatra.error'].message
    end
  end

  private

  def notify_honeybadger e
    Honeybadger.notify(
      e,
      context: {
        payload: @payload,
        config: @config
      }
    )
  end
end
