require "sinatra/base"
require "sinatra/json"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/qb_integration')

class QuickbooksEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/product_persist' do
    client = QBIntegration::Base.client(@message[:payload], @message[:message_id], @config, @message[:message])
    sku = @message[:payload][:product][:sku]
    desc = @message[:payload][:product][:description]
    price = @message[:payload][:product][:price]

    service = client.create_item(sku, desc, price)

    process_result 200, {
      'message_id' => @message[:message_id],
      'notifications' => [
        {
          "level" => "info",
          "subject" => "Imported product with SKU = #{sku} into Quickbooks"
          "description" => "Imported product with SKU = #{sku} into Quickbooks"
        }
      ]
    }
  end

  post '/persist' do
    begin
      client = QBIntegration::Base.client(@message[:payload], @message[:message_id], @config, @message[:message])
      result = client.persist
      order_number = @message[:payload]["order"]["number"]

      case @message[:message]
      when "order:new"
        process_result 200, {
          'message_id' => @message[:message_id],
          'notifications' => [
            {
              "level" => "info",
              "subject" => "Created Quickbooks sales receipt #{result["xref"][:id]} for order #{order_number}",
              "description" => "Quickbooks SalesReceipt id = #{result["xref"][:id]} and idDomain = #{result["xref"][:id_domain]}"
            }
          ]
        }
      when "order:updated"
        process_result 200, {
          'message_id' => @message[:message_id],
          'notifications' => [
            {
              "level" => "info",
              "subject" => "Updated the Quickbooks sales receipt #{result["xref"][:id]} for order #{order_number}",
              "description" => "Quickbooks SalesReceipt id = #{result["xref"][:id]} and idDomain = #{result["xref"][:id_domain]}"
            }
          ]
        }
      end
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
