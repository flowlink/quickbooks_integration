require "sinatra/base"
require "sinatra/json"
require "endpoint_base"
require "./lib/client.rb"
Dir['./lib/**/*.rb'].each { |f| require f }

class QuickbooksEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/import' do
    order_import = OrderImporter.new(@message[:payload], @config)
    begin
      result = order_import.consume
      code = 200
    rescue Exception => e
      code = 500
      result = json({"error" => e.message})
    end
    process_result code, result
  end

  post '/update' do
    order_update = OrderUpdater.new(@message[:payload], @config)
    begin
      result = order_update.consume
      code = 200
    rescue Exception => e
      code = 500
      result = json({"error" => e.message})
    end
    process_result code, result

  end

  post '/status/:id_domain/:id' do
    order_status = StatusChecker.new(@message[:payload], @config)
    order_status.id = params[:id]
    order_status.id_domain = params[:id_domain]
    begin
      result = order_status.consume
      code = 200
    rescue Exception => e
      code = 500
      result = json({"error" => e.message})
    end
    process_result code, result
  end
end
