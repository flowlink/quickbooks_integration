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

      def access_token
        @access_token ||= QBIntegration::Auth.new(
          @config.merge({
            token: @config.dig("quickbooks_access_token"),
            secret: @config.dig("quickbooks_access_secret")
          })
        ).access_token
      end
    end
  end
end
