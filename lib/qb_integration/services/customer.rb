module QBIntegration
  module Service
    class Customer < Base
      attr_reader :order

      def initialize(config, payload)
        super("Customer", config)

        @order = payload[:order] || payload[:invoice] || {}
        @customer = payload[:customer]
      end

      def create_customer
        if found_customer = find_customer
          build found_customer
          quickbooks.update found_customer
        else
          new_customer = create_model
          build new_customer
          quickbooks.create new_customer
        end
      rescue Quickbooks::IntuitRequestException => e
        check_duplicate_name(e)
      end

      def update
        unless found_customer = find_customer
          raise RecordNotFound.new "No Customer found with given name: #{@customer[:name]}"
        end
        build found_customer
        quickbooks.update found_customer
      rescue RecordNotFound => e
        check_param(e)
      end

      def find_customer
        found_by_email = find_by_email @customer[:email]
        found_by_name = find_by_name @customer[:name]

        if @customer[:qbo_id]
          find_by_id @customer[:qbo_id].to_s
        elsif found_by_name
          found_by_name
        elsif found_by_email.size > 1
          raise MultipleMatchingRecords.new "Multiple customers found with email: #{@customer[:email]}"
        elsif found_by_email.size == 1
          found_by_email.first
        else
          nil
        end
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("Id", "=", id)
        customer = @quickbooks.query("select * from Customer where #{clause}").entries.first
        raise RecordNotFound.new "No Customer id: '#{id}' defined in service" unless customer
        customer
      end

      def find_by_name(name)
        return [] unless name
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("DisplayName", "=", name)
        @quickbooks.query("select * from Customer where #{clause}").entries.first
      end

      def find_by_email(email)
        return [] unless email
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("PrimaryEmailAddr", "=", email)
        @quickbooks.query("select * from Customer where #{clause}").entries
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
        name = use_web_orders? ? quickbooks_generic_customer_name : nil
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
        unless name && name != ''
          name = order['customer']['name']
        end

        name
      end

      def create
        new_customer = create_model
        if use_web_orders?
          new_customer.display_name = quickbooks_generic_customer_name
        else
          new_customer.given_name = order['billing_address'].nil? ? 'NotProvided' :
                                                                    order['billing_address']['firstname']
          new_customer.family_name = order['billing_address'].nil? ? 'NotProvided' :
                                                                     order['billing_address']['lastname']
          new_customer.display_name = display_name
          new_customer.email_address = order[:email]
          new_customer.primary_phone = order[:phone] if order[:phone]

          new_customer.billing_address = Address.build order["billing_address"]
          new_customer.shipping_address = Address.build order["shipping_address"]
        end

        quickbooks.create new_customer
      end

      private

      def build(new_customer)
        new_customer.display_name = @customer[:name]
        new_customer.email_address = @customer[:email]
        new_customer.primary_phone = @customer[:phone]

        new_customer.billing_address = Address.build @customer[:billing_address]
        new_customer.shipping_address = Address.build @customer[:shipping_address]
      end

      def check_param(e)
        if config.fetch("quickbooks_create_or_update") == "1"
          new_customer = create_model
          build new_customer
          quickbooks.create new_customer
        else
          raise e
        end
      end

      def check_duplicate_name(e)
        if e.message.match(/Duplicate/)
          update
        else
          raise e
        end
      end

        def use_web_orders?
          config['quickbooks_web_orders_users'].to_s == "1"
        end

        # Default this to true for backwards compatibility with QBO integration users
        def create_new_customers?
          check_customers = find_value("quickbooks_create_new_customers", order, config)
          check_customers == "empty" ? true : check_customers == "1"
        end

        def find_value(key_name, payload_object, parameters)
          payload_object.fetch(key_name,  parameters.fetch(key_name, "empty")).to_s
        end

        def quickbooks_generic_customer_name
          order['quickbooks_generic_customer_name'] || config['quickbooks_generic_customer_name'] || "Web Orders" 
        end

    end
  end
end
