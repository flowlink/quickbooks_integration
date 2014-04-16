require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/qb_integration')

class QuickbooksEndpoint < EndpointBase::Sinatra::Base 
  post '/add_product' do
    begin
      code, summary = QBIntegration::Product.new(@payload, @config).import
      result code, summary
    rescue => e
      result 500, "#{e.message} #{e.backtrace.join("\n")}"
    end
  end

  post '/update_product' do
    begin
      code, summary = QBIntegration::Product.new(@payload, @config).import
      result code, summary
    rescue => e
      result 500, "#{e.message} #{e.backtrace.join("\n")}"
    end
  end

  post '/add_order' do
    begin
      code, summary = QBIntegration::Order.new(@payload, @config).create
      result code, summary
    rescue => e
      result 500, "#{e.message} #{e.backtrace.join("\n")}"
    end
  end

  post '/update_order' do
    begin
      code, summary = QBIntegration::Order.new(@payload, @config).update
      result code, summary
    rescue => e
      result 500, "#{e.message} #{e.backtrace.join("\n")}"
    end
  end

  post '/cancel_order' do
    begin
      code, summary = QBIntegration::Order.new(@payload, @config).cancel
      result code, summary
    rescue => e
      result 500, "#{e.message} #{e.backtrace.join("\n")}"
    end
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
