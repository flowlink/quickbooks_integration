module QBIntegration
  class Auth
    attr_reader :token, :secret, :accesstoken, :refreshtoken

    def initialize(credentials = {})
      #oauth v1
      @token  = credentials[:token]
      @secret = credentials[:secret]
      #oauth v2
      @accesstoken = credentials[:access_token]
      @refreshtoken = credentials[:refresh_token]
    end

    def access_token
      if token
        @access_token ||= OAuth::AccessToken.new(oauth1_consumer, token, secret)
      else
        OAuth2::AccessToken.new(
          oauth2_consumer, 
          accesstoken, 
          { :refresh_token => refreshtoken }
        ).refresh!

      end
    end

    private

    def oauth1_consumer
      OAuth::Consumer.new(ENV['QB_CONSUMER_KEY'], ENV['QB_CONSUMER_SECRET'],
                          site:                'https://oauth.intuit.com',
                          request_token_path:  '/oauth/v1/get_request_token',
                          authorize_url:       'https://appcenter.intuit.com/Connect/Begin',
                          access_token_path:   '/oauth/v1/get_access_token')
    end

    def oauth2_consumer
      oauth_params = {
        :site => "https://appcenter.intuit.com/connect/oauth2",
        :authorize_url => "https://appcenter.intuit.com/connect/oauth2",
        :token_url => "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
      }
      OAuth2::Client.new(ENV['QB_CONSUMER_CLIENT_ID'], ENV['QB_CONSUMER_CLIENT_SECRET'], oauth_params)
    end
  end
end
