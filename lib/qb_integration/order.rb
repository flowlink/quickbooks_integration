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
        line_items: format_line_items(qbo_order.line_items),
        currency: qbo_order.currency_ref.value,
        customer: customer_email(qbo_order.customer_ref.value),
        placed_on: qbo_order.meta_data["create_time"],
        updated_at: qbo_order.meta_data["last_updated_time"],
        # TODO: totals,
        payments: format_payments(qbo_order.payment_ref_number),
        shipping_address: Address.as_flowlink_hash(qbo_order.ship_address),
        billing_address: Address.as_flowlink_hash(qbo_order.bill_address)
      }
    end

    private

    def format_line_items(line_items)
      reject_items = /shipping|tax|discount/
      sales_line_details = line_items.select { |line| line.detail_type.to_s == "SalesItemLineDetail" }
      filtered_line_items = sales_line_details.reject{ |line| line.sales_item_line_detail["item_ref"]["name"].downcase.match(reject_items) }
      filtered_line_items.map do |line_item|
        {
          id: line_item.sales_item_line_detail["item_ref"]["value"],
          name: line_item.sales_item_line_detail["item_ref"]["name"],
          description: line_item.description,
          price: line_item.sales_item_line_detail["unit_price"].truncate(2).to_s('F'),
          quantity: line_item.sales_item_line_detail["quantity"].to_i
        }
      end
    end

    def format_payments(payments_ref)
      return [] if payments_ref.nil?
      payment = payment_service.find_by_id(payments_ref)
      [payment.total]
    end

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
