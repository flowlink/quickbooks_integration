module QBIntegration
  module Service
    class Customer < Base
      attr_reader :order

      def initialize(config, payload)
        super("Customer", config)

        @order = payload[:order] || payload[:invoice] || payload[:credit_memo] || {}
        @customer = payload[:customer] || @order[:customer]
      end

      def create_customer
        if found_customer = find_customer
          build(found_customer)
          quickbooks.update(found_customer)
        else
          new_customer = create_model
          build(new_customer)
          quickbooks.create(new_customer)
        end
      rescue Quickbooks::IntuitRequestException => e
        check_duplicate_name(e)
      end

      def update
        unless found_customer = find_customer
          raise RecordNotFound.new "No Customer found with given name: #{@customer[:name]}"
        end
        build(found_customer)
        quickbooks.update(found_customer)
      rescue RecordNotFound => e
        check_param(e)
      end

      def find_customer
        found_by_email = find_by_email(@customer[:email])
        found_by_name = find_by_name(@customer[:name])

        if @customer[:qbo_id]
          find_by_id(@customer[:qbo_id].to_s)
        elsif found_by_name
          found_by_name
        elsif found_by_email.size > 1
          found_by_email_then_filtered = determine_which_customer_based_on_param(found_by_email)
          return found_by_email_then_filtered unless found_by_email_then_filtered.nil?

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
        return unless name
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
        unless found_or_created_customer = fetch_by_display_name(name)
          found_or_created_customer = find_customer if @customer

          if create_new_customers?
            found_or_created_customer = create if found_or_created_customer.nil?
          else
            raise RecordNotFound.new "Quickbooks record not found for customer: #{display_name}" if found_or_created_customer.nil?
          end
        end

        found_or_created_customer
      end

      def fetch_by_display_name(name = nil)
        name_to_search = name || display_name
        return if name_to_search.nil?
        find_by_name(name_to_search)
      end

      # If someone changes the display name via Quickbooks ui we
      # will probably lose track of this customer and create another one
      # Client's now have ability to run a customer sync and configure automatic customer creation as well
      def display_name
        first = determine_name('firstname')
        last = determine_name('lastname')
        name = "#{first} #{last}" if first || last
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
          new_customer.given_name = determine_name('firstname')
          new_customer.family_name = determine_name('lastname')
          new_customer.display_name = display_name
          new_customer.email_address = @customer ? @customer[:email] : order[:email]
          new_customer.primary_phone = primary_phone if primary_phone

          new_customer.billing_address = new_customer_address("billing_address")
          new_customer.shipping_address = new_customer_address("shipping_address")
        end

        quickbooks.create(new_customer)
      end

      private

      def build(new_customer)
        new_customer.display_name = @customer[:name]
        new_customer.email_address = @customer[:email]
        new_customer.primary_phone = Phone.build(@customer[:phone])

        new_customer.billing_address = Address.build(@customer[:billing_address])
        new_customer.shipping_address = Address.build(@customer[:shipping_address])
      end

      def check_param(e)
        if config.fetch("quickbooks_create_or_update") == "1"
          new_customer = create_model
          build(new_customer)
          if config.fetch("realmId") == "123146406203559"
            puts new_customer.inspect
          end
          quickbooks.create(new_customer)
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

      def determine_name(name_field)
        name = 'NotProvided'
        name = order['billing_address'][name_field] unless order['billing_address'].nil?
        if @customer
          name = @customer['billing_address'][name_field] if @customer['billing_address']
        end

        name = name.strip unless name.nil?
        
        name
      end

      def primary_phone
        return Phone.build(@customer[:billing_address][:phone]) if @customer && @customer[:billing_address]
        Phone.build(order[:phone]) if order[:phone]
      end

      def new_customer_address(address)
        return Address.build(@customer[address]) if @customer
        Address.build(order[address])
      end

      def determine_which_customer_based_on_param(customers)
        if config['multiple_email_fallback'] == 'last_updated'
          customers.sort_by {|obj| obj.meta_data['last_updated_time']}.last
        else
          nil
        end
      end

      def multiple_email_fallback
        order['multiple_email_fallback'] ||
        @customer['multiple_email_fallback'] ||
        config['multiple_email_fallback'] ||
        nil
      end

      def use_web_orders?
        return config['quickbooks_web_orders_users'].to_s == "1" unless @customer && @customer['is_b2b']
        config['quickbooks_web_orders_users'].to_s == "1" && !@customer['is_b2b']
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
        customer_generic_name = @customer ? @customer['quickbooks_generic_customer_name'] : nil

        customer_generic_name ||
        order['quickbooks_generic_customer_name'] ||
        config['quickbooks_generic_customer_name'] ||
        "Web Orders" 
      end
    end
  end
end
