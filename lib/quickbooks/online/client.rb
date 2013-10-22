module Quickbooks
  module Online
    class Client < Quickbooks::Base

      def status_service
        not_supported!
      end

      def persist
        receipt = receipt_service.create(sales_receipt)
        puts receipt.inspect
        @id = receipt.success.object_ref.id.value
        @idDomain = receipt.success.object_ref.id.idDomain
        xref = CrossReference.new
        xref.add(@order["number"], @id, @idDomain)
        return 200, {
          "message_id" => @message_id     }
      end

    end
  end
end