module QBIntegration
  module Service
    class Department < Base
      attr_reader :config

      def initialize(config)
        super("Department", config)

        @config = config
        @model_name = "Department"
      end

      def find_department(value)
        find_by_id(value) || find_by_name(value)
      end

      private

      def find_by_name(name)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("Name", "=", name)

        query = "SELECT * FROM Department WHERE #{clause}"
        quickbooks.query(query).entries.first
      end

      def find_by_id(id)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("id", "=", id)

        query = "SELECT * FROM Department WHERE #{clause}"
        quickbooks.query(query).entries.first
      end
    end
  end
end
