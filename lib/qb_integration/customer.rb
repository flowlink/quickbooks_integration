module QBIntegration
  class Customer < Base
    attr_reader :customers, :page_num, :new_page_number

    def initialize(message = {}, config)
      super
    end

    def get
      @customers, @new_page_number = customer_service.find_by_updated_at(page_number)
      summary = "Retrieved #{@customers.count} customers from QuickBooks Online"

      [summary, new_page_number, since, code]
    end

    def create
      customer = customer_service.create_customer
      updated_flowlink_customer = payload[:customer]
      updated_flowlink_customer[:qbo_id] = customer.id
      [200 , "Customer with id #{customer.id} created", updated_flowlink_customer]
    end

    def update
      customer = customer_service.update
      updated_flowlink_customer = payload[:customer]
      updated_flowlink_customer[:qbo_id] = customer.id
      [200 , "Customer with id #{customer.id} updated", updated_flowlink_customer]
    end

    def build_customer(customer)
      Processor::Customer.new(customer).as_flowlink_hash
    end

    private

    def page_number
      config.fetch("quickbooks_page_num").to_i || 1
    end

    def since
      new_page_number == 1 ? Time.now.utc.iso8601 : config.fetch("quickbooks_since")
    end

    def code
      new_page_number == 1 ? 200 : 206
    end

  end
end
