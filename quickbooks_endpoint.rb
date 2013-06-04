require "sinatra/base"
require "sinatra/json"
require "endpoint_base"
require "./lib/client.rb"
Dir['./lib/**/*.rb'].each { |f| require f }

class QuickbooksEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/import' do
    order_import = OrderImporter.new(@message[:payload], @config)
    process_result 200, order_import.consume
  end

  post '/update' do
    order_update = OrderUpdater.new(@message[:payload], @config)
    process_result 200, order_update.consume
  end

  post '/status/:id_domain/:id' do
    order_status = StatusChecker.new(@message[:payload], @config)
    order_status.id = params[:id]
    order_status.id_domain = params[:id_domain]
    process_result 200, order_status.consume
  end
end
