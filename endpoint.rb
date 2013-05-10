require "sinatra/base"
require "sinatra/json"
Dir['./lib/**/*.rb'].each { |f| require f }

class AuguryEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/' do
    json "message_id" => params['message_id'],
         "result" => "ok",
         "details" => {
           "ithink" => "it worked"
         }
  end

  post '/import' do
    order_import = OrderImporter.new(@message, config(@message))
    process_result 200, order_import.consume
  end

  post '/update' do
    order_update = OrderUpdater.new(@message, config(@message))
    process_result 200, order_update.consume
  end

  post '/status/:id_domain/:id' do
    order_status = StatusChecker.new(@message, config(@message))
    order_status.id = params[:id]
    order_status.id_domain = params[:id_domain]
    process_result 200, order_update.consume
  end
end
