module QBIntegration
  module Service
    class PurchaseOrder < Base
      attr_reader :payload, :purchase_order, :line_service, :account_service, :vendor_service

      def initialize(config, payload)
        @payload = payload
        @purchase_order = payload[:purchase_order]
        @line_service = Line.new config, payload
        @account_service = Account.new config
        @vendor_service = Vendor.new config, payload
        super("PurchaseOrder", config)
      end

      def create
        if purchase_order[:qbo_id]
          update
        else
          new_purchase_order = create_model
          build new_purchase_order
          quickbooks.create new_purchase_order
        end
      end

      def update
        if purchase_order[:qbo_id]
          found = find_by_id purchase_order[:qbo_id]
        else
          found = find_by_doc_number purchase_order[:id]
        end

        if found
          build found
          quickbooks.update found
        else
          raise RecordNotFound.new "Quickbooks record not found for po: #{purchase_order[:id]}" unless config.fetch("quickbooks_create_or_update", "0") == "1"
          new_purchase_order = create_model
          build new_purchase_order
          quickbooks.create new_purchase_order
        end
      end

      def find_po(po)
        if po[:qbo_id]
          find_by_id(po[:qbo_id])
        else
          find_by_doc_number(po[:id])
        end
      end

      def add_bill_to_po(po, bill)
        # Linked Txns are read only in v3 but will be added in v4
        linked = Quickbooks::Model::LinkedTransaction.new
        linked.txn_id = bill.id
        linked.txn_type = "Bill"
        existing_txns = po.linked_transactions
        po.linked_transactions = existing_txns.push(linked)
        quickbooks.update(po)
      end

      private

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("Id", "=", id.to_s)
        quickbooks.query("select * from PurchaseOrder where #{clause}").entries.first
      end

      def find_by_doc_number(doc_number)
        query = "SELECT * FROM PurchaseOrder WHERE DocNumber = '#{doc_number}'"
        quickbooks.query(query).entries.first
      end

      def build(new_purchase_order)
        new_purchase_order.doc_number = purchase_order["id"]
        new_purchase_order.vendor_address = Address.build purchase_order["supplier_address"]
        new_purchase_order.ship_address = Address.build purchase_order["shipping_address"]

        if (purchase_order["quickbooks_vendor_id"])
          vendor_id = purchase_order["quickbooks_vendor_id"] || config.fetch("quickbooks_vendor_id")
          vendor = vendor_service.find_by_id vendor_id.to_i
          new_purchase_order.vendor_id = vendor.id
        elsif purchase_order.dig("vendor", "external_id")
          vendor_id = purchase_order.dig("vendor", "external_id").to_i
          vendor = vendor_service.find_by_id vendor_id
          new_purchase_order.vendor_id = vendor.id
        else
          vendor_name = purchase_order.dig("vendor", "name") || config.fetch("quickbooks_vendor_name")
          vendor = vendor_service.find_by_name vendor_name
          new_purchase_order.vendor_id = vendor.id
        end

        account_name = purchase_order["quickbooks_account_name"] || config.fetch("quickbooks_account_name")
        account = account_service.find_by_name account_name
        new_purchase_order.ap_account_id = account.id

        line_items = line_service.build_purchase_order_lines(account, purchase_order)
        new_purchase_order.line_items = line_items
        new_purchase_order
      end
    end
  end
end
