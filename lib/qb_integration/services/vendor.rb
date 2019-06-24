module QBIntegration
  module Service
    class Vendor < Base
      attr_accessor :vendor

      def initialize(config, payload)
        @vendor = payload[:vendor]
        super("Vendor", config)
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("id", "=", id)
        found_vendor = @quickbooks.query("select * from Vendor where #{clause}").entries.first
        raise RecordNotFound.new "No Vendor with id:'#{id}' found in QuickBooks Online" unless found_vendor
        found_vendor
      end

      def find_by_name(name)
        return nil unless name
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("DisplayName", "=", name)
        @quickbooks.query("select * from Vendor where #{clause}").entries.first
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

      def find_vendor
        if vendor[:qbo_id]
          find_by_id(vendor[:qbo_id])
        else
          find_by_name(vendor[:name])
        end
      end

      def create
        if found_vendor = find_vendor
          raise AlreadyPersistedVendorException.new "Vendor with id '#{vendor[:qbo_id]}' already exists" if vendor[:qbo_id]
          raise AlreadyPersistedVendorException.new "Vendor with name '#{vendor[:name]}' already exists"
        else
          new_vendor = create_model
          build new_vendor
          @quickbooks.create(new_vendor)
        end
      end

      def update
        found_vendor = find_vendor
        raise RecordNotFound.new "No Vendor with name: '#{vendor[:name]}' found in QuickBooks Online" unless found_vendor
        build(found_vendor)
        [@quickbooks.update(found_vendor), 'updated']
      rescue RecordNotFound => e
        check_param
      end
  

      private

      def build(new_vendor)
        new_vendor.title = vendor["sysid"]
        new_vendor.display_name = vendor["name"]
        new_vendor.company_name = vendor["company"]
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
        new_vendor
      end

      def create_vendor?
        vendor['quickbooks_create_new_vendors'].to_s == '1' || config['quickbooks_create_new_vendors'].to_s == '1'
      end

      def check_param
        raise RecordNotFound.new "No Vendor with name: '#{vendor[:name]}' found in QuickBooks Online" unless create_vendor?
        new_vendor = create_model
        build(new_vendor)
        [@quickbooks.create(new_vendor), 'created']
      end

    end
  end
end
