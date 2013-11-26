class Client 
  require 'quickeebooks'
  require 'oauth'

  attr_accessor :store, :quickbooks

  def initialize(payload, message_id, config={})
    @payload = payload
    @config = config
    @message_id = message_id
    if payload['order'] and payload['order']['current']
      @order = payload['order']['current']
    elsif payload['order'] and payload['order']['actual']
      @order = payload['order']['actual']
    end
  end

  def consumer
    # The tokens below are OUR APP tokens, not the store tokens. They may want to be ENV variables
    # But are not store specific. 
    OAuth::Consumer.new('qyprdcG20NCyjy5jd7tKal9ivdOcbH', 'tC4GStCV0VjxkL5WylimDhSU89fQu56t1fWErGaR', {
      :site                 => "https://oauth.intuit.com",
      :request_token_path   => "/oauth/v1/get_request_token",
      :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
      :access_token_path    => "/oauth/v1/get_access_token"
    })
  end

  def build_service(klass)
    service = klass.new
    service.access_token = client
    service.realm_id = @config['quickbooks.realm']
    service
  end

  def status_service
    @status_service ||= build_service(Quickeebooks::Windows::Service::Status)
  end

  def account_service
    @account_service ||= build_service(Quickeebooks::Windows::Service::Account)
  end

  def receipt_service
    @receipt_service ||= build_service(Quickeebooks::Windows::Service::SalesReceipt)
  end

  def item_service
    @item_service ||= build_service(Quickeebooks::Windows::Service::Item)
  end

  def payment_method_service
    @payment_method_service ||= build_service(Quickeebooks::Windows::Service::PaymentMethod)
  end

  def ship_method_service
    @ship_method_service ||= build_service(Quickeebooks::Windows::Service::ShipMethod)
  end

  def quickbooks_customers
    return @customers if @customers
    c_service = Quickeebooks::Windows::Service::Customer.new
    c_service.access_token = client

    c_service.realm_id = @config['quickbooks.realm']
    @customers = c_service.list([],1,999).entries.collect{|s| s.name}
    return @customers
  end

  def client
    @client ||= OAuth::AccessToken.new(consumer, @config["quickbooks.access_token"], @config["quickbooks.access_secret"])
  end

  def deposit_to_account_name(name)
    map = {
     "master" =>  "Visa/MC",
       "visa" => "Visa/MC",
       "american_express" => "AmEx",
      "discover" => "Visa/MC",
      "PayPal" => "PAYPAL",
      "Purchase Order" => "Purchase Orders" }
      return map[name] || "OtherCreditCard"
  end

  def ship_method_name(name)
    map = {
    "UPS" => "UPS",
    "UPS 3-5 Days" => "UPS",
    "UPS 2-3 Days" => "UPS",
    "USPS 6-10 days" => "UPS",
    "Bits - USPS" => "US Mail",
    "FED EX" => "Federal Express",
    "Bits - UPS" => "UPS",
    "ROW" => "ROW",
    "littleBits Internal Order" => "Hand Delivered",
    "FREE SHIPPING!" => "UPS",
    "Free 2-3 Day Shipping in the U.S. (Limited time only. Restrictions apply.)" => "UPS"}
    
    if map[name]
      return map[name]
    else
      raise "No Ship Method Found"
    end
  end

  def payment_method_name(name)
        map = {
        "master" =>
          "MasterCard",
         "visa" =>
          "Visa",
        "american_express" =>
          "AmEx",
        "discover" =>
          "Discover",
        "PayPal" =>
          "PayPal"}

        return map[name] || "OtherCreditCard"
  end

  def payment_methods
    return @payment_methods if @payment_methods
    @payment_methods = payment_method_service.list.entries.collect{|s| s.name}
    return @payment_methods
  end

  def flatten_child_nodes(nodes, singular, plural=singular.pluralize)
    if nodes[plural] and nodes[plural][0] and nodes[plural][0][singular].present?
      return nodes[plural].map{|n| n[singular]}
    elsif nodes[plural]
      return nodes[plural]
    else
      return {}
    end
  end

  def item_list
    @item_list ||= item_service.list([],1,999).entries
  end

  def item_exists?(sku)
    return true if item_list.collect(&:name).include?(sku)
    false
  end
end
