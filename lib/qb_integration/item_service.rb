module QBIntegration
  module Service
    class Item
      def initialize(base)
        @base = base
        @service = @base.create_service("Item")
      end

      def create(attributes = {})
        item = fill(@base.create_model("Item"), attributes)
        @service.create item
      end

      def update(item, attributes = {})
        item = @service.update fill(item, attributes)
      end

      def find_by_sku(sku)
        response = @service.query("select * from Item where Name = '#{sku}'")
        response.entries.first
      end

      private
      def fill(item, attributes)
        attributes.each {|key, value| item.send("#{key}=", value)}
        item
      end
    end
  end
end
