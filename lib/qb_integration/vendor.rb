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
      date = config.fetch("since")
      page = config.fetch("page")
      per_page = config.fetch("per_page")

      result = vendor_service.all(date, page, per_page)
      vendors = result[:vendors].map{|vendor| as_flowlink_hash(vendor)}

      result[:total] > (per_page * page) ?  [206, vendors] : [200, vendors]
    end

    def create
      vendor = vendor_service.create
      [200 , "Vendor with id #{vendor.id} created"]
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
