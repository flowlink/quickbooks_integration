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

        if config["quickbooks_vendor_name"].present?
          vendor = vendor_service.find_by_name config.fetch("quickbooks_vendor_name")
          new_purchase_order.vendor_id = vendor.id
        end

        if config["quickbooks_account_name"].present?
          account = account_service.find_by_name config.fetch("quickbooks_account_name")
          new_purchase_order.ap_account_id = account.id
        end

        line_items = line_service.build_purchase_order_lines(account, purchase_order)
        new_purchase_order.line_items = line_items
        new_purchase_order
      end

    end
  end
end
