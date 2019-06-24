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
        if found = find_purchase_order
          raise AlreadyPersistedOrderException.new(
            "Purchase Order #{purchase_order[:id]} already exists in QuickBooks with id #{found.id} and number #{found.doc_number}"
          )
        else
          new_purchase_order = create_model
          build new_purchase_order
          quickbooks.create new_purchase_order
        end
      end

      def update
        if found = find_purchase_order
          build(found)
          [quickbooks.update(found), 'Updated']
        else
          raise RecordNotFound.new "Quickbooks record not found for PO: #{purchase_order[:id]}" unless config.fetch("quickbooks_create_or_update", "0") == "1"
          new_purchase_order = create_model
          build(new_purchase_order)
          [quickbooks.create(new_purchase_order), 'Created']
        end
      end

      def find_purchase_order
        if purchase_order[:qbo_id]
          find_by_id(purchase_order[:qbo_id])
        else
          find_by_doc_number(purchase_order[:id])
        end
      end

      private

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("Id", "=", id.to_s)
        found = quickbooks.query("select * from PurchaseOrder where #{clause}").entries.first
        raise RecordNotFound.new "No Purchase Order with id:'#{id}' found in QuickBooks Online" unless found
        found
      end

      def find_by_doc_number(doc_number)
        query = "SELECT * FROM PurchaseOrder WHERE DocNumber = '#{doc_number}'"
        quickbooks.query(query).entries.first
      end

      def build(new_purchase_order)
        new_purchase_order.doc_number = purchase_order["id"]
        new_purchase_order.vendor_address = Address.build purchase_order["supplier_address"]
        new_purchase_order.ship_address = Address.build purchase_order["shipping_address"]

        if purchase_order["quickbooks_vendor_id"]
          vendor_id = purchase_order["quickbooks_vendor_id"] || config.fetch("quickbooks_vendor_id")
          vendor = vendor_service.find_by_id vendor_id.to_i
        elsif purchase_order.dig("vendor", "external_id")
          vendor_id = purchase_order.dig("vendor", "external_id").to_i
          vendor = vendor_service.find_by_id vendor_id
        else
          vendor_name = purchase_order.dig("vendor", "name") || config.fetch("quickbooks_vendor_name")
          vendor = vendor_service.find_by_name vendor_name
          raise RecordNotFound.new "No Vendor with name: '#{vendor_name}' found in QuickBooks Online" unless vendor
        end

        new_purchase_order.vendor_id = vendor.id

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
