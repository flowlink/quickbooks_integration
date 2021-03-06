module QBIntegration
  class Vendor < Base
    attr_reader :vendor_service, :config
    attr_accessor :vendor

    def initialize(message = {}, config)
      super
      @vendor = payload[:vendor]
      @config = config
      @vendor_service = Service::Vendor.new(config, payload)
    end

    def index
      date = config.fetch("quickbooks_since")
      page = config.fetch("page", 1).to_i
      per_page = config.fetch("per_page", OBJECT_LIMIT).to_i
      result = vendor_service.all(date, page, per_page)
      vendors = result[:vendors].map{|vendor| as_flowlink_hash(vendor)}

      code = 200
      code = 206 if result[:total] > (per_page * page)

      [code, vendors]
    end

    def create
      vendor = vendor_service.create
      updated_flowlink_vendor = payload[:vendor]
      updated_flowlink_vendor[:qbo_id] = vendor.id
      [200 , "Vendor with id #{vendor.id} created", updated_flowlink_vendor]
    end

    def update
      vendor = vendor_service.update
      updated_flowlink_vendor = payload[:vendor]
      updated_flowlink_vendor[:qbo_id] = vendor.id
      [200 , "Vendor with id #{vendor.id} updated", updated_flowlink_vendor]
    end

    private

    def as_flowlink_hash(vendor)
      {
        id: vendor.id,
        qbo_id: vendor.id,
        last_updated_time: vendor.meta_data['last_updated_time'],
        name: vendor.display_name,
        phone: parse_number(vendor),
        email: parse_email(vendor),
        website: parse_website(vendor),
        address: parse_address(vendor),
        currency: vendor.currency_ref['value']
      }
    end

    def parse_address(vendor)
      unless vendor.billing_address.nil?
        {
          street1: vendor.billing_address.fetch('line1', nil),
          street2: vendor.billing_address.fetch('line2', nil),
          city: vendor.billing_address.fetch('city', nil),
          country: vendor.billing_address.fetch('country', nil),
          zipcode: vendor.billing_address.fetch('postal_code', nil),
        }.compact
      end
    end

    def parse_number(vendor)
      vendor.primary_phone.fetch('free_form_number', nil) unless vendor.primary_phone.nil?
    end

    def parse_email(vendor)
      vendor.primary_email_address.fetch('address', nil) unless vendor.primary_email_address.nil?
    end

    def parse_website(vendor)
      vendor.web_site.fetch('uri', nil) unless vendor.web_site.nil?
    end
  end
end
