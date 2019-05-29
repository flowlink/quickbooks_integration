module QBIntegration
  module Service
    class Payment < Base
      attr_accessor :vendor

      def initialize(config, payload)
        @vendor = payload[:vendor]
        super("Payment", config)
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("id", "=", id)
        vendor = @quickbooks.query("select * from Payment where #{clause}").entries.first
        raise RecordNotFound.new "No Payment '#{id}' defined in service" unless vendor
        vendor
      end
    end
  end
end
