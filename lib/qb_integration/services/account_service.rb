module QBIntegration
  module Service
    class Account < Base
      def initialize(config)
        super("Account", config)
      end

      # NOTE Can't we just do config.fetch("quickbooks.account_name") here?
      # Considering each request will only be provided with one account name
      def find_by_name(account_name)
        account = @quickbooks.query("select * from Account where Name = '#{account_name}'").entries.first

        raise Exception.new("No Account '#{account_name}' defined in service") unless account

        account
      end
    end
  end
end
