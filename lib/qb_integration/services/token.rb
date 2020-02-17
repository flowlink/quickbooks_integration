module QBIntegration
  module Service
    class Token < Base

      def initialize(config)
        super("Customer", config)
      end

      def valid?
        return true if quickbooks.query()

        false
      rescue
        false
      end
    end
  end
end
