module QBIntegration
  module Service
    class Account < Base
      def initialize(config)
        super("Account", config)
      end
      def find_by_name(account_name)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("Name", "=", account_name)
        account = @quickbooks.query("select * from Account where #{clause}").entries.first
        raise "No Account '#{account_name}' defined in service" unless account

        account
      end
    end
  end
end
