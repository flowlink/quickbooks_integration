require_relative 'lib/qb_integration'

class QuickbooksEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  set :show_exceptions, false

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

  post '/add_order' do
    begin
      code, summary = QBIntegration::Order.new(@payload, @config).create
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
      result 500, e.message
    end
  end

  post '/update_purchase_order' do
    code, summary = QBIntegration::PurchaseOrder.new(@payload, @config).update
    result code, summary
  end

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

  post '/update_order' do
    code, summary = QBIntegration::Order.new(@payload, @config).update
    result code, summary
  end

  post '/cancel_order' do
    code, summary = QBIntegration::Order.new(@payload, @config).cancel
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
    code, vendors = QBIntegration::Vendor.new(@payload, @config).index
    summary = "Retrieved #{vendors.size} vendors"
    vendors.each { |vendor| add_object :vendor, vendor }
    add_parameter "since", @config.fetch("since")
    add_parameter "page", @config.fetch("page")
    result code, summary
  end

  post '/get_inventory' do
    stock = QBIntegration::Stock.new(@payload, @config)

    if stock.name.present? && stock.item
      add_object :inventory, stock.inventory
      result 200
    elsif stock.items.present?
      stock.inventories.each { |item| add_object :inventory, item }
      add_parameter 'quickbooks_poll_stock_timestamp', stock.last_modified_date
      result 200
    else
      result 200
    end
  end

  def lookup_error_message
    case env['sinatra.error'].class.to_s
    when "Quickbooks::AuthorizationFailure"
      "Authorization failure. Please check your Quickbooks credentials"
    when "Quickbooks::ServiceUnavailable"
      "Quickbooks API appears to be inaccessible HTTP 503 returned."
    else
      env['sinatra.error'].message
    end
  end
end
