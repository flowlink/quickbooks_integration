module QBIntegration
  module Service
    class Customer < Base
      attr_reader :order

      def initialize(config, payload)
        super("Customer", config)

        @order = payload[:order]
      end

      def find_or_create
        fetch_by_display_name || create
      end

      def fetch_by_display_name
        query = "SELECT * FROM Customer WHERE DisplayName = '#{display_name}'"
        quickbooks.query(query).entries.first
      end

      # This has a unique constraint in Quickbooks api
      # see https://developer.intuit.com/docs/0025_quickbooksapi/0050_data_services/030_entity_services_reference/customer
      # So in case someone changes the display name via Quickbooks ui we
      # will probably lose track of this customer and create another one
      #
      # Maybe add another custom field to better sync customers?
      def display_name
        "#{order["billing_address"]["firstname"]} #{order["billing_address"]["lastname"]}"
      end

      def create
        new_customer = create_model

        new_customer.given_name = order["billing_address"]["firstname"]
        new_customer.family_name = order["billing_address"]["lastname"]
        new_customer.display_name = display_name
        new_customer.email_address = order[:email]

        new_customer.billing_address = Address.build order["billing_address"]
        new_customer.shipping_address = Address.build order["shipping_address"]

        quickbooks.create new_customer
      end
    end
  end
end
