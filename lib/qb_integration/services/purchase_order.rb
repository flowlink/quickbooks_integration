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
        new_purchase_order = create_model
        build new_purchase_order
        quickbooks.create new_purchase_order
      rescue RecordNotFound => e
        check_param(e, new_purchase_order)
      end

      def update
        found = find_by_doc_number(purchase_order["id"])
        raise RecordNotFound.new "Quickbooks record not found for purchase_order: #{purchase_order["id"]}" unless found
        build found
        quickbooks.update found
      end

      private

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

      def check_param(e, new_purchase_order)
        if config.fetch("create_or_update", "0") == "1"
          vendor_service.vendor = purchase_order["vendor"]
          vendor_service.create
          build new_purchase_order
          quickbooks.create new_purchase_order
        else
          raise e
        end
      end

    end
  end
end
