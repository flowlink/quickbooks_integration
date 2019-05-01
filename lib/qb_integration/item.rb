module QBIntegration
  class Item < Base
    attr_reader :items, :page_num, :new_page_number

    def initialize(message = {}, config)
      super
    end

    def get
      @items, @new_page_number = item_service.find_by_updated_at(page_number)
      summary = "Retrieved #{@items.count} items from QuickBooks Online"

      [summary, new_page_number, since, code]
    end

    def build_item(item)
      Processor::Item.new(item).as_flowlink_hash
    end

    private

    def page_number
      config.fetch("quickbooks_page_num").to_i || 1
    end

    def since
      new_page_number == 1 ? Time.now.utc.iso8601 : config.fetch("quickbooks_since")
    end

    def code
      new_page_number == 1 ? 200 : 206
    end
  end
end
