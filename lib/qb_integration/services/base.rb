module QBIntegration
  module Service
    class Base
      include Helper

      attr_reader :quickbooks, :model_name, :config

      def initialize(model_name, config)
        @model_name = model_name
        @config = config
        @quickbooks = create_service
      end

      def create(attributes = {})
        model = fill(create_model, attributes)
        quickbooks.create model
      end

      def update(model, attributes = {})
        quickbooks.update fill(model, attributes)
      end

      def create_model
        "Quickbooks::Model::#{model_name}".constantize.new
      end

      private
      def create_service
        service = "Quickbooks::Service::#{@model_name}".constantize.new
        service.access_token = access_token
        service.company_id = @config.fetch('quickbooks_realm')
        service
      end

      def fill(item, attributes)
        attributes.each {|key, value| item.send("#{key}=", value)}
        item
      end

      def access_token
        @access_token ||= QBIntegration::Auth.new(
          token: @config.fetch("quickbooks_access_token"),
          secret: @config.fetch("quickbooks_access_secret")
        ).access_token
      end
    end
  end
end
