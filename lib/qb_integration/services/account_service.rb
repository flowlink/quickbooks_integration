module QBIntegration
  module Service
    class Account
      def initialize(base)
        @base = base
        @service = @base.create_service("Account")
      end

      def find_by_name(name)
        account = @service.query("select * from Account where Name = '#{account_name}'").entries.first

        raise Exception.new("No Account '#{account_name}' defined in service") unless account

        account
      end
    end
  end
end
