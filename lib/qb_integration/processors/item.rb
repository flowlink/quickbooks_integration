module QBIntegration
  module Processor
    class Item
      include Helper
      attr_reader :item

      def initialize(item)
        @item = item
      end

      def as_flowlink_hash
        {
          id: item.id,
          q_id: item.id,
          name: item.name,
          sync_token: item.sync_token,
          sku: item.sku,
          description: item.description,
          active: item.active?,
          fully_qualified_name: item.fully_qualified_name,
          taxable: item.taxable?,
          sales_tax_included: item.sales_tax_included?,
          track_quantity_on_hand: item.track_quantity_on_hand?,
          purchase_tax_included?: item.purchase_tax_included?,
          unit_price: item.unit_price,
          rate_percent: item.rate_percent,
          type: item.type,
          purchase_desc: item.purchase_desc,
          level: item.level,
          purchase_cost: item.purchase_cost,
          quantity_on_hand: item.quantity_on_hand.to_f,
          inv_start_date: item.inv_start_date,
          sub_item: item.sub_item?,
          income_account_ref: build_ref(item.income_account_ref),
          expense_account_ref: build_ref(item.expense_account_ref),
          asset_account_ref: build_ref(item.asset_account_ref),
          sales_tax_code_ref: build_ref(item.sales_tax_code_ref),
          purchase_tax_code_ref: build_ref(item.purchase_tax_code_ref),
          # parent_ref: item.sub_item? && build_ref(item.parent_ref)
          parent_ref_id: item.parent_ref,
          vendor: build_ref(item.pref_vendor_ref),
          relationships: [
            { object: "vendor", key: "id" }
          ]
        }
      end
    end
  end
end
