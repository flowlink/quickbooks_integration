shared_context "request parameters" do
  let(:config) do
    {
      'quickbooks_access_token'          => "qyprdhjEBfA2BI8sD7fWVPH4wL9esaKrYeWLosiPBir3pa5j",
      'quickbooks_access_secret'         => "yU7RtuM1Lot803jkkCfcyV9GePoNZGnZO8nRbBxo",
      'quickbooks_income_account'        => "Sales of Product Income",
      'quickbooks_realm'                 => "835973000",
      'quickbooks_inventory_costing'     => true,
      'quickbooks_inventory_account'     => "Inventory Asset",
      'quickbooks_deposit_to_account_name' => "Inventory Asset",
      'quickbooks_cogs_account'          => "Cost of Goods Sold",
      'quickbooks_payment_method_name' => [{ "visa" => "Discover" }],
      'quickbooks_account_name' => "Inventory Asset",
      'quickbooks_shipping_item' => "Shipping Charges",
      'quickbooks_tax_item' => "State Sales Tax-NY",
      'quickbooks_discount_item' => "Discount"
    }
  end
end
