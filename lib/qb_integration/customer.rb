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

    def build_customer(customer)
      {
        id: customer.id,
        q_id: custmer.id,
        created_at: customer.meta_data['create_time'],
        title: customer.title,
        given_name: customer.given_name,
        middle_name: customer.middle_name,
        family_name: customer.family_name,
        company_name: customer.company_name,
        display_name: customer.display_name,
        print_on_check_name: customer.print_on_check_name,
        active: customer.active?,
        primary_phone: customer.primary_phone,
        alternate_phone: customer.alternate_phone,
        mobile_phone: customer.mobile_phone,
        fax_phone: customer.fax_phone,
        primary_email_address: email(customer),
        web_site: customer.web_site,
        job: customer.job,
        bill_with_parent: customer.bill_with_parent,
        parent_ref: customer.parent_ref,
        level: customer.level,
        sales_term_ref: customer.sales_term_ref,
        payment_method_ref: customer.payment_method_ref,
        balance: customer.balance,
        open_balance_date: customer.open_balance_date,
        balance_with_jobs: customer.balance_with_jobs,
        preferred_delivery_method: customer.preferred_delivery_method,
        resale_num: customer.resale_num,
        suffix: customer.suffix,
        fully_qualified_name: customer.fully_qualified_name,
        taxable: customer.taxable,
        default_tax_code_ref: customer.default_tax_code_ref,
        notes: customer.notes,
        billing_address: build_address(customer.billing_address),
        shipping_address: build_address(customer.shipping_address),
        currency: customer.currency_ref ? customer.currency_ref['name'] : '',
        currency_value: customer.currency_ref ? customer.currency_ref['value'] : '',
        currency_type: customer.currency_ref ? customer.currency_ref['type']: ''
      }
    end

    private

    def email(customer)
      customer.primary_email_address ? customer.primary_email_address.address : ''
    end

    def build_address(addr)
      return unless addr
      {
        id: addr["id"],
        address1: addr["line1"],
        address2: addr["line2"],
        address3: addr["line3"],
        address4: addr["line4"],
        address5: addr["line5"],
        city: addr["city"],
        country: addr["country"],
        state: addr["country_sub_division_code"],
        country_sub_division_code: addr["country_sub_division_code"],
        zipcode: addr["postal_code"],
        note: addr["note"],
        lat: addr["lat"],
        lon: addr["lon"]
      }
    end

    def page_number
      config.fetch("quickbooks_page_num") || 1
    end

    def since
      new_page_number == 1 ? Time.now.utc.iso8601 : config.fetch("quickbooks_since")
    end

    def code
      new_page_number == 1 ? 200 : 206
    end
  end
end
