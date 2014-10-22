module QBIntegration
  class Auth
    attr_reader :token, :secret

    def initialize(credentials = {})
      @token  = credentials[:token]
      @secret = credentials[:secret]
    end

    def access_token
      @access_token ||= OAuth::AccessToken.new(consumer, token, secret)
    end

    private

    def consumer
      OAuth::Consumer.new(ENV['QB_CONSUMER_KEY'], ENV['QB_CONSUMER_SECRET'],
                          site:                'https://oauth.intuit.com',
                          request_token_path:  '/oauth/v1/get_request_token',
                          authorize_url:       'https://appcenter.intuit.com/Connect/Begin',
                          access_token_path:   '/oauth/v1/get_access_token')
    end
  end
end
