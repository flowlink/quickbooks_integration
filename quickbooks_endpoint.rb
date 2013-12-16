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

      # case @message[:message]
      # when "order:new"
      #   process_result 200, {
      #     'message_id' => @message[:message_id],
      #     'notifications' => [
      #       {
      #         "level" => "info",
      #         "subject" => "Created Quickbooks sales receipt #{sales_receipt.id} for order #{sales_receipt.doc_number}",
      #         "description" => "Quickbooks SalesReceipt id = #{result["xref"][:id]}"
      #       }
      #     ]
      #   }
      # when "order:updated"
      #   process_result 200, {
      #     'message_id' => @message[:message_id],
      #     'notifications' => [
      #       {
      #         "level" => "info",
      #         "subject" => "Updated the Quickbooks sales receipt #{result["xref"][:id]} for order #{order_number}",
      #         "description" => "Quickbooks SalesReceipt id = #{result["xref"][:id]} and idDomain = #{result["xref"][:id_domain]}"
      #       }
      #     ]
      #   }
      # end
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
