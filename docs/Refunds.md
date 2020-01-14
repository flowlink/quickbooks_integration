# /add_refund_receipt

## General Params

- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item => **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item => **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item => **Required**
- quickbooks_payment_method_name - Mapping for payment methods in QuickBooks Online => **Required**
- quickbooks_deposit_to_account_name - The Account Name in which Sales Receipts should be deposited (normally Undeposited Funds)  => **Required**
- quickbooks_prefix - Prefix to prepend to the reference number for the Refund Receipt
- quickbooks_payment_ref_number - Payment reference number to which this refund receipt should be associated

## Customer Specific Params

- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer instead of creating new customers => **Required**
- quickbooks_generic_customer_name - Name of the Customer used when rolling up customers into a general QuickBooks Online customer. Order payload field takes precedence over workflow parameter. Defaults to "Web User" if neither order payload or parameter are set. Unused if quickbooks_web_orders_users is false.
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Order is not found  => **Not Required, but if you absolutely don't want to create a new customer then set this to 0**

## Item Creation Params

- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Order are not found  => **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account - Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**

## Extra Params (not required)

The below params are checked in the following order:

data_object[:quickbooks_param_id] ||
config[:quickbooks_param_id] ||
data_object[:quickbooks_param_name] ||
config[:quickbooks_param_name]

- quickbooks_department_ + (id || name) - Name or ID of the department in QBO
- quickbooks_shipping_method_ + (id || name) - Name or ID of the shipping method in QBO
- quickbooks_currency_ + (id || name) - Name or ID of the currency in QBO
- quickbooks_class_ + (id || name) - Name or ID of the class in QBO
