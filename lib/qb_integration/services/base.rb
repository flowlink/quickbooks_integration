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

      
      private
      def create_service
        service = "Quickbooks::Service::#{@model_name}".constantize.new
        Quickbooks.sandbox_mode = true if @config.dig('quickbooks_sandbox').to_s == "1"
        service.company_id = @config.dig('quickbooks_realm') || @config.dig('realmId') 
        service
      end

      def fill(item, attributes)
        attributes.each {|key, value| item.send("#{key}=", value)}
        item
      end

    end
  end
end
