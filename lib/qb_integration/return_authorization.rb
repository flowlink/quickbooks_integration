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

    # TODO check return_authorization:updated messages
    def sync
      if sales_receipt = sales_receipt_service.find_by_order_number
        credit_memo = credit_memo_service.create_from_return ra, sales_receipt
        text = "Created Quickbooks credit memo #{credit_memo.id} for return #{ra[:number]}"
        [200, notification(text)]
      else
        [500, notification("Received return for order not sync with quickbooks", "error")]
      end
    end

    def sales_receipt_service
      Service::SalesReceipt.new(config, payload, dependencies: false)
    end

    def notification(text, level = 'info')
      { 'message_id' => message_id,
        'notifications' => [
          {
            'level' => level,
            'subject' => text,
            'description' => text
          }
        ]
      }.with_indifferent_access
    end
  end
end
