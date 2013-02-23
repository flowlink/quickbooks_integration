require "sinatra/base"
require "sinatra/json"

class AuguryEndpoint < Sinatra::Base
  helpers Sinatra::JSON

  post '/' do
    puts params
    json "message_id" => params['message_id'],
         "result" => "ok",
         "details" => {
           "ithink" => "it worked"
         }
  end
end
