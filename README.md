![CircleCI](https://circleci.com/gh/Crowdtilt/WebService-Stripe/tree/master.svg?style=shield&circle-token=505028f8a50599823a5f7bba3eede65733d1ec77)

# NAME

WebService::Stripe - Stripe API bindings

# VERSION

version 1.0300

# SYNOPSIS

    my $stripe = WebService::Stripe->new(
        api_key => 'secret',
        version => '2014-11-05', # optional
    );
    my $customer = $stripe->get_customer('cus_57eDUiS93cycyH');

# TESTING

Set the PERL\_STRIPE\_TEST\_API\_KEY environment variable to your Stripe test
secret, then run tests as you normally would using prove.

# HEADERS

WebService::Stripe supports passing custom headers to any API request by passing a hash of header values as the optional `headers` named parameter:

    $stripe->create_charge({ ... }, headers => { stripe_account => "acct_123" })

Note that header names are normalized: `foo_bar`, `Foo-Bar`, and `foo-bar` are equivalent.

Three headers stand out in particular:

- Stripe-Version

    This indicates the version of the Stripe API to use. If not given, we default to `2014-11-05`, which is the earliest version of the Stripe API to support marketplaces.

- Stripe-Account

    This specifies the ID of the account on whom the request is being made. It orients the Stripe API around that account, which may limit what records or actions are able to be taken. For example, a \`get\_card\` request will fail if given the ID of a card that was not associated with the account.

- Idempotency-Key

    All POST methods support idempotent requests through setting the value of an Idempotency-Key header. This is useful for preventing a request from being executed twice, e.g. preventing double-charges. If two requests are issued with the same key, only the first results in the creation of a resource; the second returns the latest version of the existing object.

    This feature is in ALPHA and subject to change without notice. Contact Stripe to confirm the latest behavior and header name.

# METHODS

## get\_customer

    get_customer($id)

Returns the customer for the given id.

## create\_customer

    create_customer($data)

Creates a customer.
The `$data` hashref is optional.
Returns the customer.

Example:

    $customer = $stripe->create_customer({ email => 'bob@foo.com' });

## update\_customer

    update_customer($id, data => $data)

Updates a customer.
Returns the updated customer.

Example:

    $customer = $stripe->update_customer($id, data => { description => 'foo' });

## get\_customers

    get_customers(query => $query)

Returns a list of customers.
The query param is optional.

## next

    next($collection)

Returns the next page of results for the given collection.

Example:

    my $customers = $stripe->get_customers;
    ...
    while ($customers = $stripe->next($customers)) {
        ...
    }

## create\_recipient

    create_recipient($data)

Creates a recipient.
The `$data` hashref is required and must contain at least `name` and
`type` (which can be `individual` or `corporate` as per Stripe's
documentation), but can contain more (see Stripe Docs).
Returns the recipient.

Example:

    $recipient = $stripe->create_recipient({
        name => 'John Doe',
        type => 'individual,
    });

## get\_recipient

    get_recipient($id)

Retrieves a recipient by id.
Returns the recipient.

Example:

    $recipient = $stripe->get_recipient('rcp_123');

## create\_card

    create_card($data, customer_id => 'cus_123')

## get\_charge

    get_charge($id, query => { expand => ['customer'] })

Returns the charge for the given id. The optional :$query parameter allows
passing query arguments. Passing an arrayref as a query param value will expand
it into Stripe's expected array format.

## create\_charge

    create_charge($data)

Creates a charge.

## capture\_charge

    capture_charge($id, data => $data)

Captures the charge with the given id.
The data param is optional.

## refund\_charge

    refund_charge($id, data => $data)

Refunds the charge with the given id.
The data param is optional.

## refund\_app\_fee

    refund_app_fee($fee_id, data => $data)

Refunds the application fee with the given id.
The data param is optional.

## update\_charge

    update_charge($id, data => $data)

Updates an existing charge object.

## add\_source

    add_source($cust_id, $card_data)

Adds a new funding source (credit card) to an existing customer.

## get\_token

    get_token($id)

## create\_token

    create_token($data)

## get\_account

    get_account($id)

## create\_account

    create_account($data)

## update\_account

    update_account($id, data => $data)

## get\_platform\_account

    get_platform_account($id)

## upload\_identity\_document

Uploads a photo ID to an account.

Example:

    my $account = $stripe->create_account({
        managed => 'true',
        country => 'CA',
    });

    my $file = $stripe->upload_identity_document( $account, '/tmp/photo.png' );
    $stripe->update_account( $account->{id}, data => {
        legal_entity[verification][document] => $file->{id},
    });

## add\_bank

    add_bank($data, account_id => $account_id)

Add a bank to an account.

Example:

    my $account = $stripe->create_account({
        managed => 'true',
        country => 'CA',
    });

    my $bank = $stripe->add_bank(
        {
            'bank_account[country]'        => 'CA',
            'bank_account[currency]'       => 'cad',
            'bank_account[routing_number]' => '00022-001',
            'bank_account[account_number]' => '000123456789',
        },
        account_id => $account->{id},
    );

    # or add a tokenised bank

    my $bank_token = $stripe->create_token({
        'bank_account[country]'        => 'CA',
        'bank_account[currency]'       => 'cad',
        'bank_account[routing_number]' => '00022-001',
        'bank_account[account_number]' => '000123456789',
    });

    $stripe->add_bank(
        { bank_account => $bank_token->{id} },
        account_id => $account->{id},
    );

## update\_bank

    update_bank($id, account_id => $account_id, data => $data)

## create\_transfer

    create_transfer($data)

## get\_transfer

    get_transfer($id)

## get\_transfers

    get_transfers(query => $query)

## update\_transfer

    update_transfer($id, data => $data)

## cancel\_transfer

    cancel_transfer($id)

## reverse\_transfer

Reverses an existing transfer.

[Stripe Documentation](https://stripe.com/docs/api/python#transfer_reversals)

Example:

    $ws_stripe->reverse_transfer(
        # Transfer ID (required)
        $xfer_id,
        data => {
            # POST data (optional)
            refund_application_fee        => 'true',
            amount                        => 100,
            description                   => 'Invoice Correction',
            'metadata[local_reversal_id]' => 'rvrsl_123',
            'metadata[requester]'         => 'John Doe'
        },
        headers => {
            # Headers (optional)
            stripe_account => $account->{'id'}
        }
    );

## get\_balance

    get_balance()

## get\_bitcoin\_receivers

    get_bitcoin_receivers()

## create\_bitcoin\_receiver

    create_bitcoin_receiver($data)

Example:

    my $receiver = $stripe->create_bitcoin_receiver({
        amount   => 100,
        currency => 'usd',
        email    => 'bob@tilt.com',
    });

## get\_bitcoin\_receiver

    get_bitcoin_receiver($id)

## get\_event

    get_event($id)

Returns an event for the given id.

## get\_events

    get_events(query => $query)

Returns a list of events.
The query param is optional.

## create\_access\_token

    create_access_token($data)

Creates an access token for the Stripe Connect oauth flow
[https://stripe.com/docs/connect/reference#post-token](https://stripe.com/docs/connect/reference#post-token)

# AUTHORS

- Naveed Massjouni <naveed@vt.edu>
- Dan Schmidt <danschmidt5189@gmail.com>
- Chris Behrens <chris@tilt.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Tilt, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
