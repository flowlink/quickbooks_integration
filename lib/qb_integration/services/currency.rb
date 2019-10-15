module QBIntegration
  module Service
    class Currency < Base
      attr_reader :config

      def initialize(config)
        super("Currency", config)

        @config = config
        @model_name = "Currency"
      end

      def find_currency(value)
        find_by_id(value) || find_by_name(value)
      end

      private

      def find_by_name(name)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("Name", "=", name)

        query = "SELECT * FROM Currency WHERE #{clause}"
        quickbooks.query(query).entries.first
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("id", "=", id)

        query = "SELECT * FROM Currency WHERE #{clause}"
        quickbooks.query(query).entries.first
      end
    end
  end
end
