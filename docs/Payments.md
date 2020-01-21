# Payment Endpoints

## /add_payment

- quickbooks_payment_method_name - Mapping for payment methods in QuickBooks Online => **Required**
- allow_unapplied_payment - If this parameter is set, payments that have no transaction ID on them will still be created in QBO. They will have no related transaction.
- deposit_to_account - Name for the GL account to which the payment should be deposited

## /get_payments

- quickbooks_poll_stock_timestamp - This is a timestamp => **Required**
- quickbooks_page_num - Integer. Should be set to 1 to start. The Integration will update and reset as needed => **Required**
