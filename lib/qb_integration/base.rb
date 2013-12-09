module QBIntegration
  class Base
    attr_accessor :payload, :message_id, :config, :platform, :order, :original, :xref, :message_name

    def self.client(payload, message_id, config, message_name)
      klass = "QBIntegration::Online::Client"
      klass.constantize.new(payload, message_id, config, message_name)
    end

    def initialize(payload = {}, message_id = nil, config = nil, message_name = nil)
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

    def build_receipt_header
      receipt_header = create_model("SalesReceiptHeader")
      receipt_header.doc_number = @order['number']
      receipt_header.total_amount = @order['totals']['order']
      timezone = get_config!("quickbooks.timezone")

      utc_time = Time.parse(@order["placed_on"])
      tz = TZInfo::Timezone.get(timezone)

      txn_date = Quickeebooks::Common::DateTime.new
      txn_date.value = tz.utc_to_local(utc_time).to_s
      receipt_header.txn_date = txn_date
      receipt_header.shipping_address = quickbook_address(@order["shipping_address"])

      receipt_header.ship_method_name = @order["shipments"].first["shipping_method"]

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

    def ship_method_name(shipping_method)
      ship_method_name_mapping = get_config!("quickbooks.ship_method_name")
      lookup_value!(ship_method_name_mapping.first, shipping_method)
    end

    def payment_method(payment_name)
      payment_method_name_mapping = get_config!("quickbooks.payment_method_name")
      lookup_value!(payment_method_name_mapping.first, payment_name)
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

    def persist
      order_number = @order["number"]
      order_xref = @xref.lookup(order_number)
      case @message_name
      when "order:new"
        if order_xref
          raise AlreadyPersistedOrderException.new(
            "Got 'order:new' message for order #{order_number} that already has a
            sales receipt with id: #{order_xref[:id]} and domain: #{order_xref[:id_domain]}"
          )
        end
      when "order:updated"
        if !order_xref
          raise NoReceiptForOrderException.new("Got 'order:updated' message for order #{order_number} that has not a sales receipt for it yet.")
        end
      end
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
