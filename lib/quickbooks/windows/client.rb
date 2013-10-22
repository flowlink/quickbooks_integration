module Quickbooks
  module Windows
    class Client < Quickbooks::Base

      def build_receipt_header
        header = super
        header.class_name = get_config!("quickbooks.receipt_header_class_name")
        return header
      end

      def sales_receipt
        receipt = create_model("SalesReceipt")
        receipt.line_items = @order["line_items"].each do |line_item|
          sales_receipt_line_item = create_model("SalesReceiptLineItem")
          sales_receipt_line_item.quantity = line_item["quantity"]
          sales_receipt_line_item.unit_price = line_item["price"]
          sales_receipt_line_item.item_name = line_item["sku"]
          sales_receipt_line_item.desc = line_item["name"]
          sales_receipt_line_item
        end

        adjustments = Adjustment.new(@original["adjustments"])

        if adjustments.shipping.any?
          adjustments.shipping.each do |a|
            item = create_model("SalesReceiptLineItem")
            item.quantity = 1
            item.unit_price = a["amount"]
            item.item_name = get_config!("quickbooks.shipping_item")
            receipt.line_items << item
          end
        end

        if adjustments.tax.any?
          adjustments.tax.each do |a|
            item = create_model("SalesReceiptLineItem")
            item.quantity = 1
            item.unit_price = a["amount"]
            item.item_name = get_config!("quickbooks.tax_item")
            receipt.line_items << item
          end
        end

        if adjustments.coupon.any?
          adjustments.coupon.each do |a|
            item = create_model("SalesReceiptLineItem")
            item.quantity = 1
            item.unit_price = a["amount"]
            item.item_name = get_config!("quickbooks.coupon_item")
            receipt.line_items << item
          end
        end

        if adjustments.discount.any?
          adjustments.discount.each do |a|
            item = create_model("SalesReceiptLineItem")
            item.quantity = 1
            item.unit_price = a["amount"]
            item.item_name = get_config!("quickbooks.discount_item")
            receipt.line_items << item
          end
        end
        receipt.header = build_receipt_header
        receipt
      end

      def persist
        # receipt_service = create_service("SalesReceipt")
        # created_sales_receipt = receipt_service.create(receipt)
        # @id = created_sales_receipt.success.object_ref.id.value
        # @idDomain = created_sales_receipt.success.object_ref.id.idDomain
        # xref = CrossReference.new
        # xref.add(@order["number"], @id, @idDomain)
      end

    end
  end
end