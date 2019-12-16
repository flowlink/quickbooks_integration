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

  post '/validate_token'do
    token = QBIntegration::Service::Token.new(@config)
    if token.valid?
      result 200
    else
      result 401
    end
  end

  post '/add_product' do
    code, summary, auth_info = QBIntegration::Product.new(@payload, @config).import

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/update_product' do
    code, summary, auth_info = QBIntegration::Product.new(@payload, @config).import

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/add_journal' do
    code, summary, auth_info = QBIntegration::JournalEntry.new(@payload, @config).add

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/update_journal' do
    code, summary, auth_info = QBIntegration::JournalEntry.new(@payload, @config).update

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/delete_journal' do
    code, summary, auth_info = QBIntegration::JournalEntry.new(@payload, @config).delete

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/get_orders' do
    orders, summary, new_page_number, since, code, auth_info = QBIntegration::Order.new(@payload, @config).get
    orders.each do |order|
      add_object :order, order
    end

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/add_order' do
    begin
      code, summary, added_order, auth_info = QBIntegration::Order.new(@payload, @config).create
      add_object :order, added_order

      add_parameter 'access_token', auth_info.token
      add_parameter 'refresh_token', auth_info.refresh_token

      result code, summary
    rescue QBIntegration::AlreadyPersistedOrderException => e
      notify_honeybadger e
      result 500, e.message
    end
  end

  post '/add_purchase_order' do
    begin
      code, summary, auth_info = QBIntegration::PurchaseOrder.new(@payload, @config).create

      add_parameter 'access_token', auth_info.token
      add_parameter 'refresh_token', auth_info.refresh_token

      result code, summary
    rescue QBIntegration::AlreadyPersistedOrderException => e
      notify_honeybadger e
      result 500, e.message
    end
  end

  post '/update_purchase_order' do
    code, summary, auth_info = QBIntegration::PurchaseOrder.new(@payload, @config).update

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  ### ACCOUNTTECH SPECIFIC ENDPOINT ###
  # Use the above journal endpoints for general use
  post '/add_journal_entry' do
    if @payload['journal_entry']['action'] == "ADD"
      puts 'ADD'
      code, summary, auth_info = QBIntegration::JournalEntry.new(@payload, @config).update

      add_parameter 'access_token', auth_info.token
      add_parameter 'refresh_token', auth_info.refresh_token

    elsif @payload['journal_entry']['action'] == "UPDATE"
      puts 'UPDATE'
      code, summary, auth_info = QBIntegration::JournalEntry.new(@payload, @config).update

      add_parameter 'access_token', auth_info.token
      add_parameter 'refresh_token', auth_info.refresh_token

    elsif @payload['journal_entry']['action'] == "DELETE"
      puts 'DELETE'
      code, summary, auth_info = QBIntegration::JournalEntry.new(@payload, @config).delete

      add_parameter 'access_token', auth_info.token
      add_parameter 'refresh_token', auth_info.refresh_token

    else
      code = 200
      summary = "No Valid Action Given"
    end

    result code, summary
  end
  # End of Specific Endpoint

  post '/update_order' do
    code, summary, updated_order, auth_info = QBIntegration::Order.new(@payload, @config).update

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token
    
    add_object :order, updated_order
    
    result code, summary
  end

  post '/cancel_order' do
    code, summary, auth_info = QBIntegration::Order.new(@payload, @config).cancel

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token
    
    result code, summary
  end

  post '/add_invoice' do
    begin
      code, summary, auth_info = QBIntegration::Invoice.new(@payload, @config).create
      
      add_parameter 'access_token', auth_info.token
      add_parameter 'refresh_token', auth_info.refresh_token

      result code, summary
    rescue QBIntegration::AlreadyPersistedInvoiceException => e
      notify_honeybadger e
      result 500, e.message
    end
  end

  post '/update_invoice' do
    code, summary, auth_info = QBIntegration::Invoice.new(@payload, @config).update

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token
    
    result code, summary
  end

  post '/get_invoices' do
    qbo_invoice = QBIntegration::Invoice.new(@payload, @config)
    summary, page, since, code, auth_invoice = qbo_invoice.get()
  
    qbo_invoice.invoices.each do |invoice|
      add_object :invoice, qbo_invoice.build_invoice(invoice, @config)
    end
    add_parameter 'quickbooks_page_num', page
    add_parameter 'quickbooks_since', since

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token
  
    result code, summary
  end

  post '/add_return' do
    code, summary, auth_info = QBIntegration::ReturnAuthorization.new(@payload, @config).create

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/update_return' do
    code, summary, auth_info = QBIntegration::ReturnAuthorization.new(@payload, @config).update

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/set_inventory' do
    code, summary, auth_info = QBIntegration::Stock.new(@payload, @config).set

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/get_vendors' do
    code, vendors, auth_info = QBIntegration::Vendor.new(@payload, @config).index
    summary = "Retrieved #{vendors.size} vendors"
    vendors.each { |vendor| add_object :vendor, vendor }
    add_parameter "since", @config.fetch("quickbooks_since")
    add_parameter "page", @config.fetch("page", 1)

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/add_vendor' do
    code, summary, vendor, auth_info = QBIntegration::Vendor.new(@payload, @config).create

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    add_object :vendor, vendor
    result code, summary
  end

  post '/update_vendor' do
    code, summary, vendor, auth_info = QBIntegration::Vendor.new(@payload, @config).update

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    add_object :vendor, vendor
    result code, summary
  end

  post '/get_inventory' do
    stock = QBIntegration::Stock.new(@payload, @config)

    if stock.name.present? && stock.item
      add_object :inventory, stock.inventory

      add_parameter 'access_token', stock.auth_info.token
      add_parameter 'refresh_token', stock.auth_info.refresh_token

      result 200
    elsif stock.items.present?
      stock.inventories.each { |item| add_object :inventory, item }
      add_parameter 'quickbooks_poll_stock_timestamp', stock.last_modified_date

      add_parameter 'access_token', stock.auth_info.token
      add_parameter 'refresh_token', stock.auth_info.refresh_token

      result 200
    else
      result 200
    end
  end

  post '/get_customers' do
    qbo_customer = QBIntegration::Customer.new(@payload, @config)
    summary, page, since, code, auth_info = qbo_customer.get()

    qbo_customer.customers.each do |customer|
      add_object :customer, qbo_customer.build_customer(customer)
    end

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    add_parameter 'quickbooks_page_num', page
    add_parameter 'quickbooks_since', since
    result code, summary
  end

  post '/add_customer' do
    code, summary, customer, auth_info = QBIntegration::Customer.new(@payload, @config).create

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    add_object :customer, customer
    result code, summary
  end

  post '/update_customer' do
    code, summary, customer, auth_info = QBIntegration::Customer.new(@payload, @config).update

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    add_object :customer, customer
    result code, summary
  end

  post '/get_products' do
    qbo_item = QBIntegration::Item.new(@payload, @config)
    summary, page, since, code, auth_info = qbo_item.get()

    qbo_item.items.each do |item|
      add_object :product, qbo_item.build_item(item)
    end

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    add_parameter 'quickbooks_page_num', page
    add_parameter 'quickbooks_since', since

    result code, summary
  end

  post '/add_payment' do
    code, summary, auth_info = QBIntegration::Payment.new(@payload, @config).create

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

    result code, summary
  end

  post '/get_payments' do
    qbo_payment = QBIntegration::Payment.new(@payload, @config)
    summary, page, since, code, auth_info = qbo_payment.get()

    qbo_payment.new_or_updated_payments.each do |payment|
      add_object :payment, qbo_payment.build_payment(payment)
    end

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token
    add_parameter 'quickbooks_page_num', page
    add_parameter 'quickbooks_since', since
    
    result code, summary
  end

  post '/add_bill_to_purchase_order' do
    code, summary, bill, po, auth_info = QBIntegration::Bill.new(@payload, @config).create

    add_parameter 'access_token', auth_info.token
    add_parameter 'refresh_token', auth_info.refresh_token

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
