module QBIntegration
  module Processor
    class InvoiceLine
      attr_reader :line

      def initialize(line)
        @line = line
      end

      def as_flowlink_hash
        {
          id: line.id,
          line_num: line.line_num,
          description: line.description,
          amount: line.amount,
          detail_type: line.detail_type,
          line_detail: build_details
        }
      end

      private

      def build_details
        if line.sales_item?
          build_sales_line
        elsif line.group_line_detail?
          raise FeatureNotAvailableYet.new("Group Line Not available. Please contact FlowLink support for more detail")
          # build_group_line
        elsif line.sub_total_item?
          build_sub_total_line
        elsif line.discount_item?
          # build_discount_line
          raise FeatureNotAvailableYet.new("Discount Line Not available. Please contact FlowLink support for more detail")
        end
      end
      
      def build_sales_line
        {
          item: line_ref(line.sales_line_item_detail, 'item_ref'),
          class: line_ref(line.sales_line_item_detail, 'class_ref'),
          price_level: line_ref(line.sales_line_item_detail, 'price_level_ref'),
          tax_code: line_ref(line.sales_line_item_detail, 'tax_code_ref'),
          unit_price: line.sales_line_item_detail["unit_price"],
          rate_percent: line.sales_line_item_detail["rate_percent"],
          quantity: line.sales_line_item_detail["quantity"],
          service_date: line.sales_line_item_detail["service_date"]
        }
      end

      def build_sub_total_line
        {
          item: line_ref(line.sub_total_line_detail, 'item_ref'),
          class: line_ref(line.sub_total_line_detail, 'class_ref'),
          tax_code: line_ref(line.sub_total_line_detail, 'tax_code_ref'),
          unit_price: line.sub_total_line_detail["unit_price"],
          quantity: line.sub_total_line_detail["quantity"]
        }
      end

      def line_ref(item, name)
        return {} unless item
        build_ref(item[name])
      end
  
      def build_ref(ref)
        return {} unless ref
        { name: ref["name"],id: ref["value"] }
      end
  
    end
  end

  class FeatureNotAvailableYet < StandardError; end

end