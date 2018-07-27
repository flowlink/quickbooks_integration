module QBIntegration
  class ReturnAuthorization < Base
    attr_reader :order, :ra

    def initialize(message = {}, config)
      super
      @ra = payload[:return]
    end

    def create
      if sales_receipt = sales_receipt_service.find_by_order_number
        credit_memo = credit_memo_service.create_from_return ra, sales_receipt
        text = "Created Quickbooks Credit Memo #{credit_memo.id} for return #{ra[:number]}"
        [200, text]
      else
        [500, "Received return for order not sync with quickbooks"]
      end
    end

    def update
      # TODO should be able to remove this first check when recreating
      # vcr cassetes
      if sales_receipt = sales_receipt_service.find_by_order_number

        if credit_memo = credit_memo_service.find_by_number(ra[:number])
          credit_memo_service.update credit_memo, ra, sales_receipt
          text = "Updated Quickbooks Credit Memo #{credit_memo.id} for return #{ra[:number]}"
          [200, text]
        else
          credit_memo = credit_memo_service.create_from_return ra, sales_receipt
          text = "Created Quickbooks Credit Memo #{credit_memo.id} for return #{ra[:number]}"
          [200, text]
        end
      else
        [500, "Received return for order not sync with quickbooks"]
      end
    end

    def sales_receipt_service
      Service::SalesReceipt.new(config, payload, dependencies: false)
    end
  end
end
