module QBIntegration
  module Service
    class PurchaseOrder < Base
      attr_reader :payload, :purchase_order, :line_service, :account_service, :vendor_service

      def initialize(config, payload)
        @payload = payload
        @purchase_order = payload[:purchase_order]
        @line_service = Line.new config, payload
        @account_service = Account.new config
        @vendor_service = Vendor.new config
        super("PurchaseOrder", config)
      end

      def create
        new_purchase_order = create_model
        build new_purchase_order
        quickbooks.create new_purchase_order
      end

      private

      def build(new_purchase_order)
        new_purchase_order.doc_number = purchase_order["id"]
        new_purchase_order.vendor_address = Address.build purchase_order["supplier_address"]
        new_purchase_order.ship_address = Address.build purchase_order["shipping_address"]

        vendor_name = purchase_order["quickbooks_vendor_name"] || config.fetch("quickbooks_vendor_name")
        vendor = vendor_service.find_by_name vendor_name
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
