require 'quickeebooks'
require 'oauth'
require 'tzinfo'

module Quickbooks
  class Base

    VALID_PLATFORMS = %w(Online Windows)

    attr_accessor :payload, :message_id, :config, :platform, :order, :original, :xref, :message_name

    def self.client(payload, message_id, config, message_name)
      raise LookupValueNotFoundException.new("Can't find the key quickbooks.platform in the provided mapping") unless config['quickbooks.platform']
      platform = config['quickbooks.platform'].capitalize
      raise InvalidPlatformException.new("We cannot create the Quickbooks #{platform} client") unless VALID_PLATFORMS.include?(platform)
      klass = "Quickbooks::#{platform}::Client"
      klass.constantize.new(payload,message_id,config,platform, message_name)
    end

    def initialize(payload, message_id, config, platform, message_name)
      @payload = payload
      @message_id = message_id
      @config = config
      @platform = platform
      @order = payload['order']
      @original = payload['original']
      @xref = CrossReference.new
      @message_name = message_name
    end

    def status_service
      @status_service ||= create_service("Status")
    end

    def item_service
      @item_service ||= create_service("Item")
    end

    def receipt_service
      @receipt_service ||= create_service("SalesReceipt")
    end

    def customer_service
      @customer_service ||= create_service("Customer")
    end

    def account_service
      @account_service ||= create_service("Account")
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

    def build_receipt_header
      receipt_header = create_model("SalesReceiptHeader")
      receipt_header.doc_number = @order['number']
      receipt_header.deposit_to_account_name = deposit_account_name(payment_method_name)
      # we do not create the account, will raise an exception when the account does not exist in QB.

      receipt_header.total_amount = @order['totals']['order']
      timezone = get_config!("quickbooks.timezone")

      utc_time = Time.parse(@order["placed_on"])
      tz = TZInfo::Timezone.get(timezone)

      txn_date = Quickeebooks::Common::DateTime.new
      txn_date.value = tz.utc_to_local(utc_time).to_s
      receipt_header.txn_date = txn_date
      receipt_header.shipping_address = quickbook_address(@order["shipping_address"])

      # todo move this to ship
      receipt_header.ship_method_name = ship_method_name(@order["shipments"].first["shipping_method"])
      receipt_header.payment_method_name = payment_method(payment_method_name)

      return receipt_header
    end

    def payment_method_name
      if @original.has_key?("credit_cards") && !@original["credit_cards"].empty?
        payment_name = @original["credit_cards"].first["cc_type"]
      end
      unless payment_name
        payment_name = @original["payments"].first["payment_method"]["name"] if @original["payments"]
      end
      payment_name = "None" unless payment_name
      payment_name
    end

    def quickbook_address(order_address)
      address = create_model("Address")
      address.line1   = order_address["address1"]
      address.line2   = order_address["address2"]
      address.city    = order_address["city"]
      address.country = order_address["country"]
      address.country_sub_division_code = order_address["state"]
      address.postal_code = order_address["zipcode"]
      return address
    end

    def deposit_account_name(payment_name)
      deposit_account_name_mapping = get_config!("quickbooks.deposit_to_account_name")
      lookup_value!(deposit_account_name_mapping.first, payment_name)
    end

    def ship_method_name(shipping_method)
      ship_method_name_mapping = get_config!("quickbooks.ship_method_name")
      lookup_value!(ship_method_name_mapping.first, shipping_method)
    end

    def payment_method(payment_name)
      payment_method_name_mapping = get_config!("quickbooks.payment_method_name")
      lookup_value!(payment_method_name_mapping.first, payment_name)
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

    def persist
      raise AlreadyPersistedOrderAsNew.new("Got 'order:new' message for already persisted order") if (@xref.lookup(@order['number']) && @message_name == "order:new")
    end

    def not_supported!
      raise UnsupportedException.new("#{caller_locations(1,1)[0].label} is not supported for Quickbooks #{@platform}")
    end
  end

  class InvalidPlatformException < Exception; end
  class LookupValueNotFoundException < Exception; end
  class UnsupportedException < Exception; end
  class AlreadyPersistedOrderAsNew < Exception; end
end