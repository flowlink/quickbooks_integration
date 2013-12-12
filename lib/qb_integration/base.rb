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
  end
end
