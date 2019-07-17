module QBIntegration
  module Service
    class Bill < Base
      attr_reader :payload, :bill, :purchase_order, :purchase_order_service, :line_service

      def initialize(config, payload)
        @payload = payload
        @bill = payload[:bill]
        @purchase_order_service = PurchaseOrder.new config, payload
        @purchase_order = purchase_order_service.find_po(payload[:bill][:purchase_order])
        @line_service = Line.new config, payload
        super("Bill", config)
      end

      def create

        new_bill = create_model
        build new_bill
        created_bill = quickbooks.create new_bill
        purchase_order_service.add_bill_to_po(purchase_order, created_bill)
        created_bill

      end

      private

      def build(new_bill)
        new_bill.vendor_ref = purchase_order.vendor_ref
        line_items = line_service.build_item_based_lines(bill, purchase_order)
        new_bill.line_items = line_items
        new_bill.doc_number = bill["id"]

        linked = Quickbooks::Model::LinkedTransaction.new
        linked.txn_id = purchase_order.id
        linked.txn_type = "PurchaseOrder"
        new_bill.linked_transactions = [linked]

        new_bill
      end

      def find_by_doc_number(doc_number)
        query = "SELECT * FROM Bill WHERE DocNumber = '#{doc_number}'"
        quickbooks.query(query).entries.first
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("Id", "=", id.to_s)
        found = quickbooks.query("select * from Bill where #{clause}").entries.first
        raise RecordNotFound.new "No Purchase Order with id:'#{id}' found in QuickBooks Online" unless found
        found
      end

    end
  end
end
