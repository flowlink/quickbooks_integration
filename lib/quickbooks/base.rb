require 'quickeebooks'
require 'oauth'

module Quickbooks
  class Base

    VALID_PLATFORMS = %w(Online Windows)

    attr_accessor :payload, :message_id, :config, :platform, :order

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
      @order = payload['original']
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

    def build_receipt_header
      receipt_header = create_model("SalesReceiptHeader")
      receipt_header.doc_number = @order['number']
      receipt_header.deposit_to_account_name = deposit_account_name(payment_method_name)
      # we do not create the account, will raise an exception when the account does not exist in QB.

      receipt_header.total_amount = @order['total']
      timezone = get_config!("quickbooks.timezone")
      receipt_header.txn_date = Time.parse(@order['completed_at']).in_time_zone(timezone).strftime("%Y-%m-%d")

      receipt_header.customer_name = "#{@order["bill_address"]["firstname"]} #{@order["bill_address"]["lastname"]}"
      receipt_header.shipping_address = quickbook_address(@order["ship_address"])
      receipt_header.note = [@order["bill_address"]["firstname"],@order["bill_address"]["lastname"]].join(" ")
      receipt_header.ship_method_name = ship_method_name(@order["shipments"].first["shipping_method"]["name"])

      receipt_header.payment_method_name = payment_method(payment_method_name)
      return receipt_header
    end

    def payment_method_name
      if @order.has_key?("credit_cards")
        payment_name = @order["credit_cards"].first["cc_type"]
      end
      unless payment_name
        payment_name = @order["payments"].first["payment_method"]["name"] if @order["payments"]
      end
      payment_name = "None" unless payment_name
      payment_name
    end

    def quickbook_address(order_address)
      address = create_model("Address")
      address.line1   = [order_address["firstname"], order_address["lastname"]].join(" ")
      address.line2   = order_address["address1"]
      address.line3   = order_address["address2"]
      address.city    = order_address["city"]
      address.country = order_address["country"]["name"]
      address.country_sub_division_code = order_address["state_name"]
      address.country_sub_division_code ||= order_address["state"]["name"] if order_address["state"]
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

    def not_supported!
      raise UnsupportedException.new("#{caller_locations(1,1)[0].label} is not supported for Quickbooks #{@platform}")
    end
  end

  class InvalidPlatformException < Exception; end
  class LookupValueNotFoundException < Exception; end
  class UnsupportedException < Exception; end
end