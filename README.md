# Paypal Permissions

Ruby implementation of the [PayPal Permissions API](https://www.x.com/community/ppx/permissions).

Please visit PayPal's [Permissions Service API developer forums](https://www.x.com/community/ppx/permissions?view=discussions) for questions about the Permissions API.

## Example

### Step 1: Direct the user to the "Grant Permissions" on PayPal

~~~~~ ruby
paypal = Paypal::Permissions::Paypal.new( userid, password, signature, application_id, :production )
request_data = paypal.request_permissions(
  [:express_checkout, :direct_payment, :auth_capture, :refund, :transaction_details],
  'http://localhost/callback_url'
)

# Send the browser to :permissions_url to grant permission to your application
redirect_to request_data[:permissions_url]
~~~~~

### Step 2: Lookup result to get the final permission token

~~~~~ ruby
paypal = Paypal::Permissions::Paypal.new( userid, password, signature, application_id, :production )
token_data = paypal.get_access_token( params['token'], params['verifier'] )

# Save token_data[:token] and token_data[:token_secret]
~~~~~

### Step 3: Make API calls with the `X-PP-AUTHORIZATION` header

Use the `:token` and `:token_secret`, along with your own API credentials, to create the `X-PP-AUTHORIZATION` header.

~~~~~ ruby
signature = paypal.generate_signature(api_key, secret, token, token_secret, 'POST', 'https://api.paypal.com/nvp')
header = { 'X-PP-AUTHORIZATION' => signature }
~~~~~

### Lookup granted permissions

~~~~~ ruby
scopes = paypal.lookup_permissions paypal_token
~~~~~

### Cancel granted permissions

~~~~~ ruby
paypal.cancel_permissions paypal_token
~~~~~

## Available Permissions

    :express_checkout
    :direct_payment
    :settlement_consolidation
    :settlement_reporting
    :auth_capture
    :mobile_checkout
    :billing_agreement
    :reference_transaction
    :air_travel
    :mass_pay
    :transaction_details
    :transaction_search
    :recurring_payments
    :account_balance
    :encrypted_website_payments
    :refund
    :non_referenced_credit
    :button_manager
    :manage_pending_transaction_status
    :recurring_payment_report
    :extended_pro_processing_report
    :exception_processing_report
    :account_management_permission

## Copyright

Copyright (c) 2011 Recurly. MIT License

Original version by Isaac Hall.
