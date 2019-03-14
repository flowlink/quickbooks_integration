module QBIntegration
  module Processor
    class Customer
      include Helper
      attr_reader :customer

      def initialize(customer)
        @customer = customer
      end

      def as_flowlink_hash
        {
          id: customer.id,
          q_id: customer.id,
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
          primary_email_address: email,
          web_site: customer.web_site,
          job: customer.job,
          bill_with_parent: customer.bill_with_parent,
          parent: build_ref(customer.parent_ref),
          level: customer.level,
          sales_term: build_ref(customer.sales_term_ref),
          payment_method: build_ref(customer.payment_method_ref),
          balance: customer.balance,
          open_balance_date: customer.open_balance_date,
          balance_with_jobs: customer.balance_with_jobs,
          preferred_delivery_method: customer.preferred_delivery_method,
          resale_num: customer.resale_num,
          suffix: customer.suffix,
          fully_qualified_name: customer.fully_qualified_name,
          taxable: customer.taxable,
          default_tax_code: build_ref(customer.default_tax_code_ref),
          notes: customer.notes,
          billing_address: build_address(customer.billing_address),
          shipping_address: build_address(customer.shipping_address),
          currency: build_ref(customer.currency_ref)
        }
      end

      private

      def email
        customer.primary_email_address ? customer.primary_email_address.address : ''
      end

    end
  end
end
