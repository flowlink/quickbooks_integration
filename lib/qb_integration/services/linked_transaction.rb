module QBIntegration
  module Service
    class LinkedTransaction
      attr_reader :items, :transaction_lines

      def initialize(items)
        @items = items
        @transaction_lines = []
      end

      def build
        items.each do |txn|
          transaction_lines.push build_transaction_line(txn)
        end

        transaction_lines
      end

      private

      # TODO:
      # Per Intuit Docs: https://developer.intuit.com/app/developer/qbo/docs/api/accounting/all-entities/payment
      # If any element in any line needs to be updated, all the Line elements of the Payment object have to be provided.
      #  This is true for full or sparse update. Lines can be updated only ALL or NONE.
      def build_transaction_line(txn)
        linked_transaction = Quickbooks::Model::LinkedTransaction.new
        linked_transaction.txn_id = txn.id
        linked_transaction.txn_type = txn.class.name.split('::').last

        linked_transaction
      end

    end
  end
end