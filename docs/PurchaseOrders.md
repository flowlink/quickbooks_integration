# Purchase Order Endpoints

## /add_purchase_order

- quickbooks_vendor_id - ID of the Vendor in QuickBooks. This is an option to quickly and easily find the vendor that should be associated with the Purchase Order
- quickbooks_vendor_name - Name of the Vendor in QuickBooks. This is the secondary option to quickly and easily find the vendor that should be associated with the Purchase Order
- quickbooks_account_name - Name of the GL account to use for the Purchase Order

## /update_purchase_order

- quickbooks_vendor_id - ID of the Vendor in QuickBooks. This is an option to quickly and easily find the vendor that should be associated with the Purchase Order
- quickbooks_vendor_name - Name of the Vendor in QuickBooks. This is the secondary option to quickly and easily find the vendor that should be associated with the Purchase Order
- quickbooks_account_name - Name of the GL account to use for the Purchase Order
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the purchase order if it is not found in QuickBooks => **Required**
