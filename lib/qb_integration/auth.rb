module QBIntegration
  class Auth
    attr_reader :accesstoken, :refreshtoken

    def initialize(credentials = {})
      #oauth v2
      @accesstoken = credentials[:access_token]
      @refreshtoken = credentials[:refresh_token]
    end

    def access_token
      OAuth2::AccessToken.new(
          oauth2_consumer, 
          accesstoken, 
          { :refresh_token => refreshtoken }
      ).refresh!
    end

    private

    def oauth2_consumer
      oauth_params = {
        :site => "https://appcenter.intuit.com/connect/oauth2",
        :authorize_url => "https://appcenter.intuit.com/connect/oauth2",
        :token_url => "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer",
        :redirect_uri => "https://app.flowlink.io/credentials/oauth/callback"
      }
      OAuth2::Client.new(ENV['QB_CONSUMER_CLIENT_ID'], ENV['QB_CONSUMER_CLIENT_SECRET'], oauth_params)
    end
  end
end
