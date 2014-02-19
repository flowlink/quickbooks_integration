require "sinatra/base"
require "sinatra/json"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/qb_integration')

class QuickbooksEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/products' do
    code, notification = QBIntegration::Product.new(@message, @config).import
    process_result code, notification
  end

  post '/orders' do
    begin
      code, notification = QBIntegration::Order.new(@message, @config).sync
      process_result code, notification
    rescue Exception => exception
      process_result 500, {
        'message_id' => @message_id,
        'notifications' => [
          {
            "level" => "error",
            "subject" => exception.message,
            "description" => exception.backtrace.join("\n")
          }
        ]
      }
    end
  end

  post '/returns' do
    begin
      code, notification = QBIntegration::ReturnAuthorization.new(@message, @config).sync
      process_result code, notification
    rescue Exception => exception
      process_result 500, {
        'message_id' => @message_id,
        'notifications' => [
          {
            "level" => "error",
            "subject" => exception.message,
            "description" => exception.backtrace.join("\n")
          }
        ]
      }
    end
  end

  post '/monitor_stock' do
    begin
      results = { message_id: @message[:message_id] }
      if item = QBIntegration::Stock.new(@message, @config).item
        @messages = [{
          message: 'stock:actual',
          payload: { sku: item.name, quantity: item.quantity_on_hand.to_i }
        }]

        process_result 200, results.merge!({ messages: @messages })
      else
        process_result 200, results
      end
    rescue => exception
      process_result 500, {
        'message_id' => @message_id,
        'notifications' => [
          {
            "level" => "error",
            "subject" => exception.message,
            "description" => exception.backtrace.join("\n")
          }
        ]
      }
    end
  end
end
