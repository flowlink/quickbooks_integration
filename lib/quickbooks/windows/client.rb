module Quickbooks
  module Windows
    class Client < Quickbooks::Base

      def build_receipt_header
        header = super
        header.class_name = get_config!("quickbooks.receipt_header_class_name")
        return header
      end

      def persist
        # receipt_service = create_service("SalesReceipt")
        # created_sales_receipt = receipt_service.create(receipt)
        # @id = created_sales_receipt.success.object_ref.id.value
        # @idDomain = created_sales_receipt.success.object_ref.id.idDomain
        # xref = CrossReference.new
        # xref.add(@order["number"], @id, @idDomain)
      end

    end
  end
end