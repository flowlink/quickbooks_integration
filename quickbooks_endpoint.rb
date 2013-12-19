require "sinatra/base"
require "sinatra/json"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/qb_integration')

class QuickbooksEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/product_persist' do
    code, notification = QBIntegration::ProductImporter.new(@message, @config).import

    process_result code, notification
  end

  post '/order_persist' do
    begin
      code, notification = QBIntegration::OrderImporter.new(@message, @config).sync
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

  post '/return_authorization_persist' do
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
end
