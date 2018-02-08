module QBIntegration
  module Service
    class Customer < Base
      attr_reader :order

      def initialize(config, payload)
        super("Customer", config)

        @order = payload[:order] || {}
      end

      def find_or_create
        name = use_web_orders? ? "Web Orders" : nil
        fetch_by_display_name(name) || create
      end

      def fetch_by_display_name(name = nil)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("DisplayName", "=", name || display_name)

        query = "SELECT * FROM Customer WHERE #{clause}"
        quickbooks.query(query).entries.first
      end

      # This has a unique constraint in Quickbooks api
      # see https://developer.intuit.com/docs/0025_quickbooksapi/0050_data_services/030_entity_services_reference/customer
      # So in case someone changes the display name via Quickbooks ui we
      # will probably lose track of this customer and create another one
      #
      # Maybe add another custom field to better sync customers?
      def display_name
        name = 'NotProvided NotProvided'
        unless order['billing_address'].nil?
          name = "#{order['billing_address']['firstname']} #{order['billing_address']['lastname']}".strip
        end

        name
      end

      def create
        new_customer = create_model

        if use_web_orders?
          new_customer.display_name = "Web Orders"
        else
          new_customer.given_name = order['billing_address'].nil? ? 'NotProvided' :
                                                                    order['billing_address']['firstname']
          new_customer.family_name = order['billing_address'].nil? ? 'NotProvided' :
                                                                     order['billing_address']['lastname']
          new_customer.display_name = display_name
          new_customer.email_address = order[:email]

          new_customer.billing_address = Address.build order["billing_address"]
          new_customer.shipping_address = Address.build order["shipping_address"]
        end

        quickbooks.create new_customer
      end

      private
        def use_web_orders?
          config['quickbooks_web_orders_users'].to_s == "1"
        end
    end
  end
end
