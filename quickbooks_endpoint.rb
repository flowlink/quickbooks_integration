require "sinatra/base"
require "sinatra/json"
require "endpoint_base"
require "./lib/client.rb"
Dir['./lib/**/*.rb'].each { |f| require f }

class QuickbooksEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/persist' do
    client = Quickbooks::Base.client(@message[:payload], @message[:message_id], @config)
    process_result client.persist
  end

  post '/import' do
    order_import = OrderImporter.new(@message[:payload], @message[:message_id], @config)
    begin
      result = order_import.consume
      code = result.delete("code") || 200
    rescue Exception => e
      code = 500
      result = {"error" => e.message, "backtrace" => e.backtrace.inspect}
    end
    process_result code, result
  end

  post '/update' do
    order_update = OrderUpdater.new(@message[:payload], @message[:message_id], @config)
    begin
      result = order_update.consume
      code = 200
    rescue Exception => e
      code = 500
      result = {"error" => e.message}
    end
    process_result code, result

  end

  post '/status/:id_domain/:id' do
    order_status = StatusChecker.new(@message[:payload], @message[:message_id], @config)
    order_status.id = params[:id]
    order_status.idDomain = params[:id_domain]
    begin
      result = order_status.consume
      code = 200
    rescue Exception => e
      code = 500
      result = {"error" => e.message}
    end
    process_result code, result
  end
end
