module QBIntegration
  module Service
    class Vendor < Base
      attr_reader :vendor

      def initialize(config, payload)
        @vendor = payload[:vendor]
        super("Vendor", config)
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("id", "=", id)
        vendor = @quickbooks.query("select * from Vendor where #{clause}").entries.first
        raise "No Vendor '#{name}' defined in service" unless vendor
        vendor
      end

      def all(date, page, per_page)
        total = @quickbooks.all.count
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("Where Metadata.LastUpdatedTime", ">", date)
        order_by = "Order By Metadata.LastUpdatedTime"
        vendors = @quickbooks.query("select * from Vendor #{clause} #{order_by}", page: page, per_page: per_page)
        {
          vendors: vendors,
          total: total
        }
      end

      def create
        begin
          new_vendor = create_model
          build new_vendor
          @quickbooks.create new_vendor
        rescue Quickbooks::IntuitRequestException => e
          check_duplicate_name(e)
        end
      end

      def update
        updated_vendor = find_by_name vendor["name"]
        build updated_vendor
        @quickbooks.update updated_vendor
      end

      def find_by_name(name)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("CompanyName", "=", name)
        vendor = @quickbooks.query("select * from Vendor where #{clause}").entries.first
        raise "No Vendor '#{name}' defined in service" unless vendor
        vendor
      end

      private

      def check_duplicate_name(e)
        if e.message.match(/Duplicate/) && config.fetch("create_or_update", "0") == "1"
          update
        else
          raise e
        end
      end

      def build(new_vendor)
        new_vendor.title = vendor["sysid"]
        new_vendor.display_name = vendor["name"]
        new_vendor.company_name = vendor["name"]
        new_vendor.primary_phone = Phone.build(vendor["phone"])
        new_vendor.primary_email_address = Email.build(vendor["email"])
        new_vendor.billing_address = Address.build({
          "address1" => vendor["street1"],
          "address2" => vendor["street2"],
          "city" => vendor["city"],
          "country" => vendor["country"],
          "city" => vendor["city"],
          "state" => vendor["state"],
          "zipcode" => vendor["zipcode"],
        })
      end
    end
  end
end
