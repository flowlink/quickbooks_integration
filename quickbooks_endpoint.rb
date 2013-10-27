require "sinatra/base"
require "sinatra/json"
require "endpoint_base"
Dir['./lib/**/*.rb'].each { |f| require f }

class QuickbooksEndpoint < EndpointBase
  helpers Sinatra::JSON

  post '/persist' do
    client = Quickbooks::Base.client(@message[:payload], @message[:message_id], @config)
    process_result *client.persist
  end

end
