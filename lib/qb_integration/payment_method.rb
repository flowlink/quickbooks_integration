module QBIntegration
  class PaymentMethod
    attr_reader :order, :original, :config, :base, :service

    def initialize(base)
      @order = base.payload["order"]
      @original = base.payload["original"]
      @config = base.config

      @base = base
      @service = base.create_service("PaymentMethod")
    end

    def augury_name
      if original.has_key?("credit_cards") && !original["credit_cards"].empty?
        original["credit_cards"].first["cc_type"]
      elsif order["payments"]
        order["payments"].first["payment_method"]
      else
        "None"
      end
    end

    def qb_name
      payment_method_name_mapping = base.get_config!("quickbooks.payment_method_name")
      base.lookup_value!(payment_method_name_mapping.first, augury_name)
    end

    def matching_payment
      service.fetch_by_name(qb_name) ||
        (raise Exception.new("No PaymentMethod '#{qb_name}' defined in Quickbooks"))
    end
  end
end
