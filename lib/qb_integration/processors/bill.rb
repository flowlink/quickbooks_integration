module QBIntegration
  module Processor
    class Bill
      include Helper
      attr_reader :bill

      def initialize(bill)
        @bill = bill
      end

      def as_flowlink_hash
        {
          id: bill.id,
          doc_number: bill.doc_number,
          balance: bill.balance.to_i,
          last_updated_time: bill.meta_data["last_updated_time"]
        }
      end

    end
  end
end
