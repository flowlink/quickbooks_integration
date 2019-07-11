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
          invoice: QBIntegration::Invoice.new({}, {}).build_invoice(@linked_txn),
          line_extras: build_line_extras(line.line_extras)
        }.compact
      end

      private

      def build_line_extras(extras)
        extras.name_values.to_a.map do |name_value|
          {
            name: name_value.name,
            value: name_value.value
          }
        end
      end
  
    end
  end
end
