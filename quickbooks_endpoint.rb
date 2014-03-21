require "sinatra"
require "endpoint_base"
require "pry"

require File.expand_path(File.dirname(__FILE__) + '/lib/qb_integration')

class QuickbooksEndpoint < EndpointBase::Sinatra::Base 
  post '/products' do
    code, notification = QBIntegration::Product.new(@message, @config).import
    process_result code, notification
  end

  post '/add_order' do
    code, summary = QBIntegration::Order.new(@payload, @config).create
    result code, summary
  end

  post '/update_order' do
    code, summary = QBIntegration::Order.new(@payload, @config).update
    process_result code, summary
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
    if item = QBIntegration::Stock.new(@payload, @config).item
      add_object :inventory, { sku: item.name, quantity: item.quantity_on_hand.to_i }
      result 200
    else
      result 200
    end
  end
end
