module Factories
  class << self

    def order(args={})
      {
        'number' => "R#{rand(999999999)}",
        'item_total' => '47.97',
        'total' => '50.37',
        'state' => 'complete',
        'adjustment_total' => '2.4',
        'payment_total' => '0.0',
        'user_id' => '407201487',
        'created_at' => '2012-09-10T13:37:33Z',
        'updated_at' => '2012-09-10T13:37:33Z',
        'completed_at' => '2012-09-10T13:37:33Z',
        'shipment_state' => 'pending',
        'payment_state' => 'balance_due',
        'email' => 'andrew@spreecommerce.com',
        'special_instructions' => '',
        'credit_cards' => ['credit_card' => {
          'cc_type' => "visa",
          'month' => "12",
          'year' => "2014"
        }],
        'bill_address' => {
          'firstname' => 'Santina',
          'lastname' => 'Quitzon',
          'address1' => '5819 Derick Club',
          'address2' => 'Suite 240',
          'city' => 'South William',
          'zipcode' => '16804',
          'phone' => '1-252-515-0619 x9455',
          'company' => nil,
          'alternative_phone' => nil,
          'state_name' => nil,
          'country' => {
            'iso_name' => 'UNITED STATES',
            'iso' => 'US',
            'iso3' => 'USA',
            'name' => 'United States',
            'numcode' => 840
          },
          'state_name' => '',
          'state_id' => '1',
          'state' => {
            'abbr' => 'NY',
            'country_id' => 214,
            'id' => 889445952,
            'name' => 'New York'
          }
        },
        'ship_address' => {
          'firstname' => 'Santina',
          'lastname' => 'Quitzon',
          'address1' => '5819 Derick Club',
          'address2' => 'Suite 240',
          'city' => 'South William',
          'zipcode' => '16804',
          'phone' => '1-252-515-0619 x9455',
          'company' => nil,
          'alternative_phone' => nil,
          'country' => {
            'iso_name' => 'UNITED STATES',
            'iso' => 'US',
            'iso3' => 'USA',
            'name' => 'United States',
            'numcode' => 840
          },
          'state_name' => '',
          'state_id' => '1',
          'state' => {
            'abbr' => 'NY',
            'country_id' => 214,
            'id' => 889445952,
            'name' => 'New York'
          }
        },
        'line_items' => [
          { 'line_item' => {
              'id' => '988118179',
              'quantity' => '3',
              'price' => '15.99',
              'variant_id' => '215054540',
              'variant' => {
                'external_ref' => 'LB-BIT-w10-INVERTER-v03',
                'id' => '215054540',
                'name' => 'Ruby on Rails Tote',
                'count_on_hand' => '10',
                'sku' => 'LB-BIT-w10-INVERTER-v03',
                'price' => '15.99',
                'weight' => '',
                'height' => '',
                'width' => '',
                'depth' => '',
                'is_master' => 'true',
                'cost_price' => '13.0',
                'permalink' => 'ruby-on-rails-tote' }}
          }
        ],
        'payments' => [
          { 'payment' => {
              'id' => 2,
              'amount' => "67.16",
              'state' => "pending",
              'payment_method_id' => 193416319,
              'payment_method' => {
                'id' => 193416319,
                'name' => "Credit Card",
                'environment' => "development"
              }
            }
          }
        ],
        'shipments' => [
          { 'shipment' => {
              'id' => '80446377',
              'tracking' => nil,
              'number' => 'H438105531460',
              'cost' => '5.0',
              'shipped_at' => nil,
              'state' => 'pending',
              'order_id' => 'R760610137',
              'inventory_units' => [ { 'inventory_unit' => { 'id' => '55', 'variant_id' => '215054540', 'state' => "sold" } },
                                     { 'inventory_unit' => { 'id' => '56', 'variant_id' => '215054540', 'state' => "sold" } },
                                     { 'inventory_unit' => { 'id' => '57', 'variant_id' => '215054540', 'state' => "sold" } } ],
              'shipping_method' => {
                'name' => "UPS 3-5 Days",
                'pch_carrier' => 'UPS' }}},
          { 'shipment' => {
              'id' => '80446388',
              'tracking' => nil,
              'number' => 'H438105531488',
              'cost' => '10.0',
              'shipped_at' => nil,
              'state' => 'sold',
              'order_id' => 'R760610137',
              'inventory_units' => [ { 'inventory_unit' => { 'id' => '55', 'variant_id' => '215054540', 'state' => "sold" } },
                                     { 'inventory_unit' => { 'id' => '56', 'variant_id' => '215054540', 'state' => "sold" } },
                                     { 'inventory_unit' => { 'id' => '57', 'variant_id' => '215054540', 'state' => "sold" } } ],
              'shipping_method' => {
                'name' => 'UPS Ground (USD)',
                'pch_carrier' => 'UPS' }}}
        ],
        'adjustments'=> [
          {
            'adjustment'=> {
              'id'=> 1073053959,
              'amount'=> '-18.3',
              'label'=> 'Promotion (Order Refund)',
              'originator_type' => 'Spree::PromotionAction',
              'eligible' => true
               }},
          {
            'adjustment'=> {
              'id'=> 1073053960,
              'amount'=> '19.3',
              'label'=> 'Shipping',
              'originator_type' => 'Spree::ShippingMethod',
              'eligible' => true
               }},
          {
            'adjustment'=> {
              'id'=> 1073053961,
              'amount'=> '12.22',
              'label'=> 'NY Sales Tax 8.875',
              'originator_type' => 'Spree::TaxRate',
              'adjustable_type' => 'Spree::Order',
              'eligible' => true
               }},
               {
            'adjustment'=> {
              'id'=> 1073053962,
              'amount'=> '98.22',
              'label'=> 'Promotion (Refund)',
              'eligible' => false
               }}
        ]
      }.merge(args)
    end
  end
end
