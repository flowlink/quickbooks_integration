module QBIntegration
  class Base
    attr_accessor :payload, :config, :original, :xref, :message_name

    def initialize(message = {}, config)
      @payload = message[:payload]
      @original = payload[:original]
      @message_name = message[:message]
      @message_id = message[:message_id]

      @config = config
    end

    def status_service
      @status_service ||= create_service("Status")
    end

    def item_service
      @item_service ||= Service::Item.new(self)
    end

    def receipt_service
      @receipt_service ||= create_service("SalesReceipt")
    end

    def customer_service
      @customer_service ||= create_service("Customer")
    end

    def account_service
      @account_service ||= Service::Account.new(self)
    end

    def payment_method_service
      @payment_method_service ||= create_service("PaymentMethod")
    end

    def create_service(service_name)
      service = "Quickbooks::Service::#{service_name}".constantize.new
      service.access_token = access_token
      service.company_id = get_config!('quickbooks.realm')
      service
    end

    def create_model(model_name)
      "Quickbooks::Model::#{model_name}".constantize.new
    end

    def access_token
      @access_token = Auth.new(
        token: get_config!("quickbooks.access_token"),
        secret: get_config!("quickbooks.access_secret")
      ).access_token
    end

    def get_config!(key)
      lookup_value!(@config,key)
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

  class InvalidPlatformException < Exception; end
  class LookupValueNotFoundException < Exception; end
  class UnsupportedException < Exception; end
  class AlreadyPersistedOrderException < Exception; end
  class NoReceiptForOrderException < Exception; end
end
