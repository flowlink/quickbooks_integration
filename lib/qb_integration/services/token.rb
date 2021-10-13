module QBIntegration
  module Service
    class Token < Base

      def initialize(config)
        super("AccessToken", config)
      end

      def valid?
        return true if quickbooks.query()

        false
      rescue
        false
      end

      def disconnect
        quickbooks.disconnect
      end
    end
  end
end
