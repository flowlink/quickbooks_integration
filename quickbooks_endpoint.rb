require File.expand_path(File.dirname(__FILE__) + '/lib/qb_integration')

class QuickbooksEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  Honeybadger.configure do |config|
    config.api_key = ENV['HONEYBADGER_KEY']
    config.environment_name = ENV['RACK_ENV']
  end

  post '/add_product' do
    code, summary = QBIntegration::Product.new(@payload, @config).import
    result code, summary
  end

  post '/update_product' do
    code, summary = QBIntegration::Product.new(@payload, @config).import
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
end
