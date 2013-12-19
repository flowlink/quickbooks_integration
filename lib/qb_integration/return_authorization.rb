module QBIntegration
  class ReturnAuthorization < Base
    attr_reader :order, :ra

    def initialize(message = {}, config)
      super
      @ra = payload[:return_authorization]
      @order = payload[:return_authorization][:order]

      # for compatibility with sales receipt service
      payload[:order] = @order
    end

    def sync
      if sales_receipt = sales_receipt_service.find_by_order_number
        [200, notification("Hang tight - #{message_name}")]
      end
    end

    def sales_receipt_service
      Service::SalesReceipt.new(config, payload, dependencies: false)
    end

    def notification(text)
      { 'message_id' => message_id,
        'notifications' => [
          {
            'level' => 'info',
            'subject' => text,
            'description' => text
          }
        ]
      }.with_indifferent_access
    end
  end
end
