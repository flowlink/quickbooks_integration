module QBIntegration
  class Vendor < Base
    attr_reader :vendor_service
    attr_accessor :vendor

    def initialize(message = {}, config)
      super
      @vendor = payload[:vendor]
      @vendor_service = Service::Vendor.new(config)
    end

    def index
      vendors = vendor_service.all
      vendors = vendors.map{|vendor| as_flowlink_hash(vendor)}
      [200, vendors]
    end

    private 
    def as_flowlink_hash(vendor)
      {
        id: vendor.id,
        name: vendor.display_name,
        phone: vendor.primary_phone,
        email: vendor.primary_email_address,
        website: vendor.web_site,
        address: vendor.billing_address,
        currency: vendor.currency_ref['value']
      }
    end
  end
end
