module Quickbooks
  module Online
    class Client < Quickbooks::Base

      def status_service
        not_supported!
      end

      def sales_receipt
        receipt = create_model("SalesReceipt")
        receipt.header = build_receipt_header
        receipt
      end

      def find_or_create_customer


        customer_service = create_service("Customer")



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