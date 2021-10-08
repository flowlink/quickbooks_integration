module QBIntegration
    module Service
        class Oauth < Base
            def initialize(payload, config)
                @payload = payload
                #puts "hello from QBIntegration::Service::Oauth.initialize! our payload is: #{@payload}"
            end
            
            def disconnect
                request = RestClient::Request.new(
                    url: "https://developer.api.intuit.com/v2/oauth2/tokens/revoke",
                    payload: {
                      token: @payload[:parameters][:refresh_token]
                    }.to_json,
                    timeout: 1000,
                    method: :post,
                    headers: {
                        :accept => :json, 
                        :authorization => disconnect_auth_header,
                        :content_type => :json,
                    }
                )
                #puts "hello from QBIntegration::Service::Oauth.disconnect but later! built request's payload is:#{request.payload}" 
                #puts "hello from QBIntegration::Service::Oauth.disconnect but later! built request's headers are:#{request.headers.inspect}" 
                response = request.execute do |response, request, result|
                  #puts "hello from QBIntegration::Service::Oauth.disconnect but later! our code is #{response.code}" 
                  case response.code
                  when 400
                    [ :error, JSON.parse(response.to_str) ]
                  when 200
                    [ :success, JSON.parse(response.to_str) ]
                  else
                    fail "Invalid response #{response.to_str} received."
                  end
                end
            end

            private

            def disconnect_auth_header
              # build authorization header for request; refer to https://developer.intuit.com/app/developer/qbo/docs/develop/authentication-and-authorization/oauth-2.0#revoke-token-disconnect 
              encoded = Base64.strict_encode64(@payload[:parameters][:client_id] + ":" + @payload[:parameters][:client_secret])
              header = "Basic #{encoded}"
              #puts "hello from QBIntegration::Service::Oauth.authorization header! our authorization header is: #{header}"
              return header
            end


        end
    end
end
