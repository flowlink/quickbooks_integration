require "sinatra/base"
require "sinatra/json"

class AuguryEndpoint < Sinatra::Base
  helpers Sinatra::JSON

  before do
    unless request.env["HTTP_X_AUGURY_TOKEN"] == 'x123'
      halt 401
    end
  end

  post '/' do
    json "message_id" => params['message_id'],
         "result" => "ok",
         "details" => {
           "ithink" => "it worked"
         }
  end
end
