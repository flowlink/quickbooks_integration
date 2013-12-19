module QBIntegration
  class OrderImporter < Base
    attr_accessor :order

    def initialize(message = {}, config)
      super
      @order = payload['order']
    end

    def sync
      if sales_receipt = sales_receipt_service.find_by_order_number
        case message_name
        when "order:new"
          raise AlreadyPersistedOrderException.new(
            "Got 'order:new' message for order #{order[:number]} that already has a
            sales receipt with id: #{sales_receipt.id}"
          )
        when "order:canceled"
          credit_memo = credit_memo_service.create_from_receipt sales_receipt
          text = "Created Quickbooks credit memo #{credit_memo.id} for canceled order #{sales_receipt.doc_number}"
          [200, notification(text)]
        when "order:updated"
          [200, notification("hang tight not sure what to do right now")]
          # update it?
          #
          # order_number = @order["number"]
          # cross_ref_hash = @xref.lookup(order_number)
          # current_receipt = receipt_service.fetch_by_id(cross_ref_hash[:id])
          # receipt = sales_receipt
          # receipt.id = Quickeebooks::Online::Model::Id.new(cross_ref_hash[:id])
          # receipt.sync_token = current_receipt.sync_token
          # receipt = receipt_service.update(receipt)
          #   process_result 200, {
          #     'message_id' => @message[:message_id],
          #     'notifications' => [
          #       {
          #         "level" => "info",
          #         "subject" => "Updated the Quickbooks sales receipt #{result["xref"][:id]} for order #{order_number}",
          #         "description" => "Quickbooks SalesReceipt id = #{result["xref"][:id]} and idDomain = #{result["xref"][:id_domain]}"
          #       }
          #     ]
          #   }
        end
      else
        case message_name
        when "order:new", "order:updated"
          sales_receipt = sales_receipt_service.create
          text = "Created Quickbooks sales receipt #{sales_receipt.id} for order #{sales_receipt.doc_number}"
          [200, notification(text)]
        else
          raise AlreadyPersistedOrderException.new(
            "Got 'order:canceled' message for order #{order[:number]} that already has no
            sales receipt"
          )
        end
      end
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

    # TODO Understand this xref thing. Not sure we still need it
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

      case @message_name
        when "order:new"
          receipt = receipt_service.create(sales_receipt)
          id = receipt.id.value
          idDomain = receipt.id.idDomain
          cross_ref_hash = @xref.add(@order["number"], id, idDomain)
        when "order:updated"
          order_number = @order["number"]
          cross_ref_hash = @xref.lookup(order_number)
          current_receipt = receipt_service.fetch_by_id(cross_ref_hash[:id])
          receipt = sales_receipt
          receipt.id = Quickeebooks::Online::Model::Id.new(cross_ref_hash[:id])
          receipt.sync_token = current_receipt.sync_token
          receipt = receipt_service.update(receipt)
        else
          raise Exception.new("received unsupported message #{@message_name}, either use 'order:new' or 'order:updated'")
      end
      {
        "receipt" => receipt,
        "xref" => cross_ref_hash
      }
    end
  end
end
