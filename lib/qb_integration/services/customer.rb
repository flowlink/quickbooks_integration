module QBIntegration
  module Service
    class Customer < Base
      attr_reader :order

      def initialize(config, payload)
        super("Customer", config)

        @order = payload[:order] || payload[:invoice] || {}
      end

      def find_by_updated_at(page_num)
        raise MissingTimestampParam unless config["quickbooks_since"].present?

        filter = "Where Metadata.LastUpdatedTime>'#{config.fetch("quickbooks_since")}'"
        order_by = "Order By Metadata.LastUpdatedTime"
        query = "Select * from Customer #{filter} #{order_by}"
        response = quickbooks.query(query, :page => page_num, :per_page => PER_PAGE_AMOUNT)

        new_page = response.count == PER_PAGE_AMOUNT ? page_num.to_i + 1 : 1
        [response.entries, new_page]
      end

      def find_or_create
        name = use_web_orders? ? "Web Orders" : nil
        unless customer = fetch_by_display_name(name)
          if create_new_customers? || use_web_orders?
            customer = create
          else 
            raise RecordNotFound.new "Quickbooks record not found for customer: #{display_name}"
          end
        end

        customer
      end

      def fetch_by_display_name(name = nil)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("DisplayName", "=", name || display_name)

        query = "SELECT * FROM Customer WHERE #{clause}"
        quickbooks.query(query).entries.first
      end

      # If someone changes the display name via Quickbooks ui we
      # will probably lose track of this customer and create another one
      # Client's now have ability to run a customer sync and configure automatic customer creation as well
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

        # Default this to true for backwards compatibility with QBO integration users
        def create_new_customers?
          config['quickbooks_create_new_customers'] ? config['quickbooks_create_new_customers'].to_s == "1" : true
        end
    end
  end
end
