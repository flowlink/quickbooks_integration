module QBIntegration
class OrderImporter < Base
    attr_accessor :order

    def initialize(message = {}, config)
      super
      @order = payload['order']
    end

    # if canceled create credit memo (lets assume a canceled order has been
    # imported already?) TODO build it!
    #
    # NOTE do we need to care about the message name and raise? e.g. quickbooks
    # doesnt have the given order yet and but the enpdoint receives an order:updated
    # message instead of order:new
    def sync
      if sales_receipt = sales_receipt_service.find_by_order_number
        case message_name
        when "order:new"
          raise AlreadyPersistedOrderException.new(
            "Got 'order:new' message for order #{order[:number]} that already has a
            sales receipt with id: #{sales_receipt.id}"
          )
        when "order:updated"
          # update it?
          #
          # order_number = @order["number"]
          # cross_ref_hash = @xref.lookup(order_number)
          # current_receipt = receipt_service.fetch_by_id(cross_ref_hash[:id])
          # receipt = sales_receipt
          # receipt.id = Quickeebooks::Online::Model::Id.new(cross_ref_hash[:id])
          # receipt.sync_token = current_receipt.sync_token
          # receipt = receipt_service.update(receipt)
        end
      else
        case message_name
        when "order:new"
          sales_receipt = sales_receipt_service.create
          text = "Created Quickbooks sales receipt #{sales_receipt.id} for order #{sales_receipt.doc_number}"
          [200, notification(text)]
        when "order:updated"
          raise NoReceiptForOrderException.new(
            "Got 'order:updated' message for order #{order[:number]} that has not a sales receipt for it yet."
          )
        end
      end
    end

    def notification(text)
      {
        'message_id' => message_id,
        'notifications' => {
          'level' => 'info',
          'subject' => text,
          'description' => text
        }
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
