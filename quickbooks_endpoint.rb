require "sinatra/base"
require "sinatra/json"
require "endpoint_base"
Dir['./lib/**/*.rb'].each { |f| require f }

class QuickbooksEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/persist' do
    begin
      client = Quickbooks::Base.client(@message[:payload], @message[:message_id], @config, @message[:message])
      client.persist
    rescue Exception => exception
      process_result 500, {
        'message_id' => @message_id,
        'notifications' => [
          {
            "level" => "error",
            "subject" => exception.message,
            "description" => exception.backtrace
          }
        ]
      }
    end

    process_result 200, {
      'message_id' => @message_id,
      'notifications' => [
        {
          "level" => "info",
          "subject" => "persisted order #{@order["number"]} in Quickbooks",
          "description" => "Quickbooks SalesReceipt id = #{@id} and idDomain = #{@idDomain}"
        }
      ]
    }
  end

end
