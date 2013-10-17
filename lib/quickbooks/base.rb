require 'quickeebooks'
require 'oauth'

module Quickbooks
  class Base

    VALID_PLATFORMS = %w(Online Windows)

    attr_accessor :payload, :message_id, :config, :platform

    def self.client(payload, message_id, config)
      raise LookupValueNotFoundException.new("Can't find the key '#{key}' in the provided mapping") unless config['quickbooks.platform']
      platform = config['quickbooks.platform'].capitalize
      raise InvalidPlatformException.new("We cannot create the Quickbooks #{platform} client") unless VALID_PLATFORMS.include?(platform)
      klass = "Quickbooks::#{platform}::Client"
      klass.constantize.new(payload,message_id,config,platform)
    end

    def initialize(payload, message_id, config, platform)
      @payload = payload
      @message_id = message_id
      @config = config
      @platform = platform
    end

    def status_service
      @status_service ||= create_service("Status")
    end

    def create_service(service_name)
      service = "Quickeebooks::#{platform}::Service::#{service_name}".constantize.new
      service.access_token = access_token
      service.realm_id = get_config!('quickbooks.realm')
      service
    end

    def create_model(model_name)
      "Quickeebooks::#{platform}::Model::#{model_name}".constantize.new
    end

    def access_token
      @access_token ||= OAuth::AccessToken.new(consumer, get_config!("quickbooks.access_token"), get_config!("quickbooks.access_secret"))
    end

    def consumer
      @consumer ||= OAuth::Consumer.new('qyprdcG20NCyjy5jd7tKal9ivdOcbH', 'tC4GStCV0VjxkL5WylimDhSU89fQu56t1fWErGaR', {
        :site                 => "https://oauth.intuit.com",
        :request_token_path   => "/oauth/v1/get_request_token",
        :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
        :access_token_path    => "/oauth/v1/get_access_token"
      })
    end

    def get_config!(key)
      value = @config[key]
      raise LookupValueNotFoundException.new("Can't find the key '#{key}' in the provided mapping") unless value
      value
    end

    def not_supported!
      raise UnsupportedException.new("#{caller_locations(1,1)[0].label} is not supported for Quickbooks #{@platform}")
    end
  end

  class InvalidPlatformException < Exception; end
  class LookupValueNotFoundException < Exception; end
  class UnsupportedException < Exception; end
end