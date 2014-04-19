require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/qb_integration')

class QuickbooksEndpoint < EndpointBase::Sinatra::Base 
  post '/add_product' do
    begin
      code, summary = QBIntegration::Product.new(@payload, @config).import
      result code, summary
    rescue => e
      result 500, "#{e.message}"
    end
  end

  post '/update_product' do
    begin
      code, summary = QBIntegration::Product.new(@payload, @config).import
      result code, summary
    rescue => e
      result 500, "#{e.message}"
    end
  end

  post '/add_order' do
    begin
      code, summary = QBIntegration::Order.new(@payload, @config).create
      result code, summary
    rescue => e
      result 500, "#{e.message}"
    end
  end

  post '/update_order' do
    begin
      code, summary = QBIntegration::Order.new(@payload, @config).update
      result code, summary
    rescue => e
      result 500, "#{e.message}"
    end
  end

  post '/cancel_order' do
    begin
      code, summary = QBIntegration::Order.new(@payload, @config).cancel
      result code, summary
    rescue => e
      result 500, "#{e.message}"
    end
  end

  post '/add_return' do
    begin
      code, summary = QBIntegration::ReturnAuthorization.new(@payload, @config).create
      result code, summary
    rescue => e
      result 500, "#{e.message}"
    end
  end

  post '/update_return' do
    begin
      code, summary = QBIntegration::ReturnAuthorization.new(@payload, @config).update
      result code, summary
    rescue => e
      result 500, "#{e.message}"
    end
  end

  post '/get_inventory' do
    begin
      stock = QBIntegration::Stock.new(@payload, @config)

      if stock.name.present? && stock.item
        add_object :inventory, { sku: stock.item.name, quantity: stock.item.quantity_on_hand.to_i }
        result 200
      elsif stock.items.present?
        stock.inventories.each { |item| add_object :inventory, item }
        add_parameter 'quickbooks_poll_stock_timestamp', stock.last_modified_date
        result 200
      else
        result 200
      end
    rescue => e
      result 500, "#{e.message}"
    end
  end
end
