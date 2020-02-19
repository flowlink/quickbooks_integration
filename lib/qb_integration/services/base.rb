module QBIntegration
  module Service
    class Base
      include Helper

      attr_reader :quickbooks, :model_name, :config

      PER_PAGE_AMOUNT = 50

      def initialize(model_name, config)
        @model_name = model_name
        @config = config
        @quickbooks = create_service
      end

      def create(attributes = {})
        model = fill(create_model, attributes)
        quickbooks.create(model)
      end

      def update(model, attributes = {})
        quickbooks.update(fill(model, attributes))
      end

      def create_model
        "Quickbooks::Model::#{model_name}".constantize.new
      end

      def access_token
        @access_token ||= QBIntegration::Auth.new(
          @config.merge({
            token: @config.dig("quickbooks_access_token"),
            secret: @config.dig("quickbooks_access_secret")
          })
        ).access_token
      end

      private

      def create_service
        "Quickbooks::Service::#{@model_name}".constantize.new.tap do |service|
          Quickbooks.sandbox_mode = true if @config.dig('quickbooks_sandbox').to_s == "1"
          service.access_token = access_token
          service.company_id = @config.dig('quickbooks_realm') || @config.dig('realmId')
        end
      end

      def fill(item, attributes)
        attributes.each {|key, value| item.send("#{key}=", value)}
        item
      end

    end
  end
end
