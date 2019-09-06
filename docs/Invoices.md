
# /add_invoice
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item => **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item => **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item => **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer instead of creating new customers => **Required**
- quickbooks_generic_customer_name - Name of the Customer used when rolling up customers into a general QuickBooks Online customer. Invoice payload field takes precedence over workflow parameter. Defaults to "Web User" if neither invoice payload or parameter are set. Unused if quickbooks_web_orders_users is false.
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Invoice is not found  => **Not Required, but if you absolutely don't want to create a new customer then set this to 0. Otherwie**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Invoice are not found  => **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which payments from Invoices should be deposited (normally Undeposited Funds)
- quickbooks_ar_account_name - The Account Name used for your Accounts Receivable account in QuickBooks Online

# /update_invoice
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the Invoice if it is not found in QuickBooks => **Required**
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item => **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item => **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item => **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer instead of creating new customers => **Required**
- quickbooks_generic_customer_name - Name of the Customer used when rolling up customers into a general QuickBooks Online customer. Invoice payload field takes precedence over workflow parameter. Defaults to "Web User" if neither invoice payload or parameter are set. Unused if quickbooks_web_orders_users is false.
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Invoice is not found  => **Not Required, but if you absolutely don't want to create a new customer then set this to 0# /false. Otherwise it will create a new customer if none is found**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Invoice are not found  => **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which payments from Invoices should be deposited (normally Undeposited Funds)
- quickbooks_ar_account_name - The Account Name used for your Accounts Receivable account in QuickBooks Online

# /get_invoices
- quickbooks_since - Timestamp that tells the integration to retrieve all invoices that are new or have been updated since this timestamp => **Required**
- quickbooks_page_num - Number used for paginating requests. Defaults to 1 => **Required**

# Notes
When Finding/Creating a Customer during the Invoice add/update process, FlowLink uses the following logic.
- Check to see if customer exists
  - Find by generic_customer_name if parameter is set, else
  - Find by QBO ID, else
  - FInd by display name, else
  - Find by email
FlowLink will use the customer object on the Invoice payload first and then use the Invoice object if a certain field doesn't exist.
If a customer is still not found, FlowLink will create a customer unless quickbooks_create_new_customers is explicitly set to not create customers.
