module QBIntegration
  module Service
    class Item
      def initialize(base)
        @base = base
        @config = @base.config
        @service = @base.create_service("Item")
        @account_service = @base.account_service
      end

      def create(sku, desc, price, account_name)
        item = @base.create_model("Item")

        item.name = sku
        item.description = desc
        item.unit_price = price

        account = @account_service.find_by_name @config.fetch("service.account_name", "Sales")
        item.income_account_ref = account.id

        @service.create(item)
      end

      def find_by_sku(sku)
        response = @service.query("select * from Item where Name = '#{sku}'")
        response.entries.first
      end

      def update(item, attributes = {})
        attributes.each {|key, value| item.send("#{key}=", value)}

        item = @service.update(item)
      end
    end
  end
end
