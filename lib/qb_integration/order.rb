module QBIntegration
  class Order < Base
    attr_accessor :order, :new_page_number

    def initialize(message = {}, config)
      super
      @order = payload[:order]
    end

    def get
      now = Time.now.utc.iso8601
      @orders, @new_page_number = sales_receipt_service.find_by_updated_at(page_number)

      flowlink_orders = []
      @orders.each do |order|
        flowlink_order = Processor::SalesReceipt.new(order, config).as_flowlink_hash
        flowlink_order[:customer] = format_customer(order.customer_ref.value)
        flowlink_order[:payments] = format_payments(order.payment_ref_number)
        flowlink_orders << flowlink_order
      end
      summary = "Retrieved #{@orders.count} Sales Receipts from QuickBooks Online"

      [flowlink_orders, summary, new_page_number, since(now), code]
    end


    def create
      if sales_receipt = sales_receipt_service.find_by_order_number
        raise AlreadyPersistedOrderException.new(
          "Order #{order[:id]} already has a sales receipt with id: #{sales_receipt.id}"
        )
      end

      sales_receipt = sales_receipt_service.create
      updated_flowlink_order = order
      updated_flowlink_order[:qbo_id] = sales_receipt.id
      text = "Created QuickBooks Sales Receipt #{sales_receipt.id} for order #{sales_receipt.doc_number}"
      [200, text, updated_flowlink_order]
    end

    def update
      sales_receipt = sales_receipt_service.find_by_order_number
      if !sales_receipt.present? && check_field(:quickbooks_create_or_update).to_s == "1"
        sales_receipt = sales_receipt_service.create
        updated_flowlink_order = order
        updated_flowlink_order[:qbo_id] = sales_receipt.id
        [200, "Created QuickBooks Sales Receipt #{sales_receipt.doc_number}", updated_flowlink_order, sales_receipt_service.access_token]
      elsif !sales_receipt.present?
        raise RecordNotFound.new "QuickBooks Sales Receipt not found for order #{order[:number]}"
      else
        sales_receipt = sales_receipt_service.update(sales_receipt)
        updated_flowlink_order = order
        updated_flowlink_order[:qbo_id] = sales_receipt.id
        [200, "Updated QuickBooks Sales Receipt #{sales_receipt.doc_number}", updated_flowlink_order]
      end
    end

    def cancel
      unless sales_receipt = sales_receipt_service.find_by_order_number
        raise RecordNotFound.new "QuickBooks Sales Receipt not found for order #{order[:number]}"
      end

      credit_memo = credit_memo_service.create_from_receipt(sales_receipt)
      text = "Created QuickBooks Credit Memo #{credit_memo.id} for canceled order #{sales_receipt.doc_number}"
      [200, text]
    end

    private

    def format_payments(payments_ref)
      return [] if payments_ref.nil?
      payment = payment_service.find_by_id(payments_ref)
      [payment.total]
    end

    def format_customer(customer_id)
      customer = customer_service.find_by_id(customer_id)
      customer.primary_email_address['address']
    rescue NoMethodError => e
      # IF no email is found, default to the display name if a customer is found
      customer ? customer.display_name : nil
    end

    def check_field(key_name)
      order.fetch(key_name, config.fetch(key_name, false))
    end

    def page_number
      config.fetch("quickbooks_page_num").to_i || 1
    end

    def since(now)
      new_page_number == 1 ? now : config.fetch("quickbooks_since")
    end

    def code
      new_page_number == 1 ? 200 : 206
    end

  end
end
