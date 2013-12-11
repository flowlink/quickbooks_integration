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
      case @message_name
      when "product:new"    then import_new
      when "product:update" then import_update
      end
    end

    def import_new
      if item = item_service.find_by_sku(sku)
        Notification.new(
          @message_id,
          "info",
          "Unable to import product with Sku = #{sku} to Quickbooks because it was already there.",
          "Unable to import product with Sku = #{sku} to Quickbooks because it was already there."
        )
      else
        item_service.create(sku, @desc, @price, nil)

        Notification.new(
          @message_id,
          "info",
          "Imported product with Sku = #{sku} to Quickbooks successfully.",
          "Imported product with Sku = #{sku} to Quickbooks successfully."
        )
      end
    end

    def import_update
      Notification.new(123, "info", "Everything ok", "Really")
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
