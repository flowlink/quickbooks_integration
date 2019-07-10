module QBIntegration
  module Processor
    class PaymentLineItem
      include Helper
      attr_reader :line

      def initialize(line, linked_txn)
        @line = line
        @linked_txn = linked_txn
      end

      def as_flowlink_hash
        {
          id: line.id,
          line_num: line.line_num,
          description: line.description,
          amount: line.amount.to_f,
          detail_type: line.detail_type,
          invoice: QBIntegration::Invoice.new({}, {}).build_invoice(@linked_txn)
        }.compact
      end

      private
  
    end
  end
end
