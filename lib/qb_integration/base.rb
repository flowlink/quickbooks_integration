module QBIntegration
  class Base
    attr_accessor :payload, :original, :message_name, :message_id, :config

    def initialize(message = {}, config)
      @config = config

      @payload = message[:payload]
      @original = payload[:original]
      @message_name = message[:message]
      @message_id = message[:message_id]
    end

    def item_service
      @item_service ||= Service::Item.new(@config)
    end

    def account_service
      @account_service ||= Service::Account.new(@config)
    end

    def sales_receipt_service
      @receipt_service ||= create_service("SalesReceipt")
    end

    def payment_method_service
      @payment_method_service ||= PaymentMethod.new(self)
    end

    def create_service(service_name)
      service = "Quickbooks::Service::#{service_name}".constantize.new
      service.access_token = access_token
      service.company_id = get_config!('quickbooks.realm')
      service
    end

    def access_token
      @access_token = Auth.new(
        token: get_config!("quickbooks.access_token"),
        secret: get_config!("quickbooks.access_secret")
      ).access_token
    end

    def get_config!(key)
      lookup_value!(@config, key)
    end

    def lookup_value!(hash, key, ignore_case = false, default = nil)
      hash = Hash[hash.map{|k,v| [k.downcase,v]}] if ignore_case

      if default
        value = hash.fetch(key, default)
      else
        value = hash[key]
      end

      raise LookupValueNotFoundException.new("Can't find the key '#{key}' in the provided mapping") unless value
      value
    end

    def not_supported!
      raise UnsupportedException.new("#{caller_locations(1,1)[0].label} is not supported for Quickbooks #{@platform}")
    end
  end
end
