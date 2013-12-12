module QBIntegration
  class Base
    include Helper

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
      @receipt_service ||= Service::SalesReceipt.new(@config).quickbooks
    end

    def payment_method_service
      @payment_method_service ||= Service::PaymentMethod.new(config, payload)
    end

    def not_supported!
      raise UnsupportedException.new("#{caller_locations(1,1)[0].label} is not supported for Quickbooks #{@platform}")
    end
  end
end
