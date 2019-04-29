module QBIntegration
  module Service
    class Vendor < Base
      def initialize(config)
        super("Vendor", config)
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("id", "=", id)
        vendor = @quickbooks.query("select * from Vendor where #{clause}").entries.first
        raise "No Vendor '#{name}' defined in service" unless vendor
        vendor
      end

      def find_by_name(name)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("CompanyName", "=", name)
        vendor = @quickbooks.query("select * from Vendor where #{clause}").entries.first
        raise "No Vendor '#{name}' defined in service" unless vendor
        vendor
      end
    end
  end
end
