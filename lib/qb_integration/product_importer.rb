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

         notification "Updated product with Sku = #{sku} on Quickbooks successfully."
      else
        item_service.create({
          name: sku,
          description: @desc,
          unit_price: @price,
          income_account_ref: 6
        })

        notification "Imported product with Sku = #{sku} to Quickbooks successfully."
      end
    end

    def notification(text)
      Notification.new(
        @message_id,
        "info",
        text,
        text
      )
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
