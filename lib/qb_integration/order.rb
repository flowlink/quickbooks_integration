module QBIntegration
  class Order < Base
    attr_accessor :order, :new_page_number

    def initialize(message = {}, config)
      super
      @order = payload[:order]
    end

    def get
      @orders, @new_page_number = sales_receipt_service.find_by_updated_at(page_number)

      flowlink_orders = @orders.map{ |order| as_flowlink_hash(order) }
      summary = "Retrieved #{@orders.count} Sales Receipts from QuickBooks Online"

      [flowlink_orders, summary, new_page_number, since, code]
    end


    def create
      if sales_receipt = sales_receipt_service.find_by_order_number
        raise AlreadyPersistedOrderException.new(
          "Order #{order[:id]} already has a sales receipt with id: #{sales_receipt.id}"
        )
      end

      sales_receipt = sales_receipt_service.create
      text = "Created QuickBooks Sales Receipt #{sales_receipt.id} for order #{sales_receipt.doc_number}"
      [200, text]
    end

    def update
      sales_receipt = sales_receipt_service.find_by_order_number
      if !sales_receipt.present? && check_field(:quickbooks_create_or_update).to_s == "1"
        sales_receipt = sales_receipt_service.create
        [200, "Created QuickBooks Sales Receipt #{sales_receipt.doc_number}"]
      elsif !sales_receipt.present?
        raise RecordNotFound.new "QuickBooks Sales Receipt not found for order #{order[:number]}"
      else
        sales_receipt = sales_receipt_service.update sales_receipt
        [200, "Updated QuickBooks Sales Receipt #{sales_receipt.doc_number}"]
      end
    end

    def cancel
      unless sales_receipt = sales_receipt_service.find_by_order_number
        raise RecordNotFound.new "QuickBooks Sales Receipt not found for order #{order[:number]}"
      end

      credit_memo = credit_memo_service.create_from_receipt sales_receipt
      text = "Created QuickBooks Credit Memo #{credit_memo.id} for canceled order #{sales_receipt.doc_number}"
      [200, text]
    end

    def as_flowlink_hash(qbo_order)
      {
        id: qbo_order.id,
        name: qbo_order.doc_number,
        number: qbo_order.doc_number,
        created_at: qbo_order.txn_date,
        line_items: qbo_order.line_items.map{ |line_item| { id: line_item.id, description: line_item.description } },
        currency: qbo_order.currency_ref.value,
        customer: customer_email(qbo_order.customer_ref.value),
        placed_on: qbo_order.meta_data["create_time"],
        updated_at: qbo_order.meta_data["last_updated_time"],
        # TODO: totals,
        # TODO: payments
        shipping_address: Address.as_flowlink_hash(qbo_order.ship_address),
        billing_address: Address.as_flowlink_hash(qbo_order.bill_address)
      }
    end

    private

    def customer_email(customer_id)
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

    def since
      new_page_number == 1 ? Time.now.utc.iso8601 : config.fetch("quickbooks_since")
    end

    def code
      new_page_number == 1 ? 200 : 206
    end

  end
end
