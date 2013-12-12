module QBIntegration
  class ProductImporter < Base

    attr_reader :sku

    def initialize(message = {}, config)
      super

      @product = @payload[:product]
      @sku = @product[:sku]
      @desc = @product[:description]
      @price= @product[:price]
    end

    def import
      if item = item_service.find_by_sku(sku)
        item_service.update(item, { description: @description, unit_price: @price })


        [200, notification("Updated product with Sku = #{sku} on Quickbooks successfully.")]
      else
        account = account_service.find_by_name @config.fetch("quickbooks.account_name")

        item_service.create({
          name: sku,
          description: @desc,
          unit_price: @price,
          income_account_ref: account.id
        })

        [200, notification("Imported product with Sku = #{sku} to Quickbooks successfully.")]
      end
    end

    def notification(text)
      Notification.new(
        @message_id,
        "info",
        text,
        text
      ).to_json
    end
  end

  class Notification < Struct.new(:message_id, :level, :subject, :description)
    def to_json
      {
        'message_id' => message_id,
        'notifications' => [{
          'level' => level,
          'subject' => subject,
          'description' => description
        }]
      }
    end
  end
end
