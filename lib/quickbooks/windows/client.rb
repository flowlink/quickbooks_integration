module Quickbooks
  module Windows
    class Client < Quickbooks::Base

      def build_receipt_header
        header = super
        header.class_name = get_config!("quickbooks.receipt_header_class_name")
        return header
      end

    end
  end
end