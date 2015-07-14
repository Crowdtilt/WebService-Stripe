package WebService::Stripe;
use Moo;
with qw(WebService::Client);

# VERSION

use Carp qw(croak);
use HTTP::Request::Common qw( POST );
use Method::Signatures;
use constant {
    API_ROOT_URL             => 'https://api.stripe.com',
    FILE_UPLOADS_URL         => 'https://uploads.stripe.com/v1/files',
    FILE_PURPOSE_ID_DOCUMENT => 'identity_document',
    MARKETPLACES_MIN_VERSION => '2014-11-05',
};

has api_key => (
    is       => 'ro',
    required => 1,
);

has version => (
    is      => 'ro',
    default => MARKETPLACES_MIN_VERSION,
);

has '+base_url'     => ( default => API_ROOT_URL );
has '+content_type' => ( default => 'application/x-www-form-urlencoded' );

method BUILD(@args) {
    $self->ua->default_headers->authorization_basic( $self->api_key, '' );
    $self->ua->default_header( 'Stripe-Version' => $self->version );
}

method next(HashRef $thing, HashRef :$query, HashRef :$headers) {
    $query ||= {};
    return undef unless $thing->{has_more};
    my $starting_after = $thing->{data}[-1]{id} or return undef;
    return $self->get( $thing->{url},
        { %$query, starting_after => $starting_after }, headers => $headers );
}

method create_customer($data = {}, $opts = {}) {
    return $self->_stripe_req(post => '/v1/customers', $data, $opts);
}

method get_application_fee($id!, $query = {}, $opts = {}) {
    return $self->_stripe_req(get => "/v1/application_fees/$id", $query, $opts);
}

method get_balance($query = {}, $opts = {}) {
    return $self->_stripe_req(get => '/v1/balance', $query, $opts);
}

method get_customer($id!, $query = {}, $opts = {}) {
    return $self->_stripe_req(get => "/v1/customers/$id", $query, $opts);
}

method update_customer($id!, $data!, $opts = {}) {
    return $self->_stripe_req(post => "/v1/customers/$id", $data, $opts);
}

method get_customers($query = {}, $opts = {}) {
    return $self->_stripe_req(get => '/v1/customers', $query, $opts);
}

method create_card($customer_id!, $data!, $opts = {}) {
    return $self->_stripe_req(post => "/v1/customers/$customer_id/cards",
        $data, $opts);
}

method get_charge($id!, $query = {}, $opts = {}) {
    return $self->_stripe_req(get => "/v1/charges/$id", $query, $opts);
}

method create_charge($data!, $opts = {}) {
    return $self->_stripe_req(post => '/v1/charges', $data, $opts);
}

method update_charge($id, $data!, $opts = {}) {
    return $self->_stripe_req(post => "/v1/charges/$id", $data, $opts);
}

method capture_charge($id!, $data = {}, $opts = {}) {
    return $self->_stripe_req(post => "/v1/charges/$id/capture", $data, $opts);
}

method refund_charge($id!, $data = {}, $opts = {}) {
    return $self->_stripe_req(post => "/v1/charges/$id/refunds", $data, $opts);
}

method refund_app_fee($fee_id!, $data = {}, $opts = {}) {
    return $self->_stripe_req(post => "/v1/application_fees/$fee_id/refunds",
        $data, $opts);
}

method add_source($customer_id!, $data!, $opts = {}) {
    return $self->_stripe_req(post => "/v1/customers/$customer_id/sources",
        $data, $opts);
}

method create_token($data!, $opts = {}) {
    return $self->_stripe_req(post => '/v1/tokens', $data, $opts);
}

method get_token($token_id!, $query = {}, $opts = {}) {
    return $self->_stripe_req(get => "/v1/tokens/$token_id", $query, $opts);
}

method create_account($data!, $opts = {}) {
    return $self->_stripe_req(post => '/v1/accounts', $data, $opts);
}

method get_account($account_id!, $query = {}, $opts = {}) {
    return $self->_stripe_req(get => "/v1/accounts/$account_id", $query, $opts);
}

method update_account($account_id!, $data!, $opts = {}) {
    return $self->_stripe_req(post => "/v1/accounts/$account_id", $data, $opts);
}

method upload_identity_document($data!, $opts = {}) {
    my $account_id = $data->{'stripe_account'} || $opts->{'stripe_account'}
        or croak 'data.stripe_account or opts.stripe_account is required';
    my $filepath = $data->{'filepath'}
        or croak 'data.filepath is required';

    return $self->req(
        POST FILE_UPLOADS_URL,
        Stripe_Account => "$account_id",
        Content_Type   => 'form-data',
        Content        => [
            purpose => FILE_PURPOSE_ID_DOCUMENT,
            file    => [ "$filepath" ],
        ],
    );
}

method add_bank($account_id!, $data!, $opts = {}) {
    return $self->_stripe_req(post => "/v1/accounts/$account_id/bank_accounts",
        $data, $opts);
}

method update_bank($account_id!, $bank_id!, $data!, $opts = {}) {
    return $self->_stripe_req(post =>
        "/v1/accounts/$account_id/bank_accounts/$bank_id", $data, $opts);
}

method delete_bank($account_id!, $bank_id!, $data = {}, $opts = {}) {
    return $self->_stripe_req(delete =>
        "/v1/accounts/$account_id/bank_accounts/$bank_id", $data, $opts);
}

method get_banks($account_id!, $query = {}, $opts = {}) {
    return $self->_stripe_req(get => "/v1/accounts/$account_id/bank_accounts",
        $query, $opts);
}

method create_transfer($data!, $opts = {}) {
    return $self->_stripe_req(post => '/v1/transfers', $data, $opts);
}

method get_transfer($id, $query = {}, $opts = {}) {
    return $self->_stripe_req(get => "/v1/transfers/$id", $query, $opts);
}

method get_transfers($query = {}, $opts = {}) {
    return $self->_stripe_req(get => '/v1/transfers', $query, $opts);
}

method update_transfer($id, $data!, $opts = {}) {
    return $self->_stripe_req(post => "/v1/transfers/$id", $data, $opts);
}

method cancel_transfer($id, $data = {}, $opts = {}) {
    return $self->_stripe_req(post => "/v1/transfers/$id/cancel", $data, $opts);
}

method create_reversal($xfer_id, $data = {}, $opts = {}) {
    return $self->_stripe_req(post => "/v1/transfers/$xfer_id/reversals",
        $data, $opts);
}

method get_bitcoin_receivers($query = {}, $opts = {}) {
    return $self->_stripe_req(get => '/v1/bitcoin/receivers', $query, $opts);
}

method create_bitcoin_receiver($data!, $opts = {}) {
    return $self->_stripe_req(post => '/v1/bitcoin/receivers', $data, $opts);
}

method get_bitcoin_receiver($id, $data = {}, $opts = {}) {
    return $self->_stripe_req(get => "/v1/bitcoin/receivers/$id", $data, $opts);
}

method _stripe_req($verb, $path, $params, $opts) {
    my %is_header_opt = (
        idempotency_key => 1,
        stripe_account  => 1,
        stripe_version  => 1,
    );

    my $headers = $opts->{'headers'} // {};
    while (my ($name => $value) = each $opts) {
        # Ignore falsey so clients can pass undef or ''
        next unless $value;

        # Normalize option name
        $name = lc $name;
        $name =~ s/-/_/g;
        next unless $is_header_opt{ $name };

        # Set option header
        $headers->{ $name } = $value;
    }

    return $self->$verb($path, $params, headers => $headers);
}

# ABSTRACT: Stripe API bindings

=head1 SYNOPSIS

    my $stripe = WebService::Stripe->new(
        api_key => 'sk_test_123',
        version => '2014-11-05', # optional
    );
    my $customer = $stripe->get_customer('cus_57eDUiS93cycyH');

=head1 TESTING

Set the PERL_STRIPE_TEST_API_KEY environment variable to your Stripe test
secret, then run tests as you normally would using prove.

=head1 HEADERS

WebService::Stripe supports passing custom headers to any API request via the
$opts argument:

    $stripe->create_charge(\%data, { headers => { x_my_header => "..." } })

Note that header names are normalized: C<foo_bar>, C<Foo-Bar>, and C<foo-bar> are equivalent.

=head2 STRIPE HEADERS

The $opts argument provides a shortcut for passing Stripe's custom
"Stripe-Account", "Stripe-Version", and "Idempotency-Key" headers. Simply pass
any of those values in the $opts hashref (lower-cased, underscore-separated)
and they'll be added to the current request's headers.

Example:

    $stripe->get_balance({}, {
        idempotency_key => '123456abcdef',
        stripe_account  => 'acct_1',
        stripe_version  => '2015-02-10'
    });

    # Equivalent to...
    $stripe->get_balance({}, {
        headers => {
            'Idempotency-Key' => '123456abcdef',
            'Stripe-Account'  => 'acct1',
            'Stripe-Version'  => '2015-02-10'
        }
    });

=back

=head1 METHODS

=head2 get_customer

    get_customer($id)

Returns the customer for the given id.

=head2 create_customer

    create_customer($data!, $opts = {})

Creates a customer.
The C<$data> hashref is optional.
Returns the customer.

Example:

    $customer = $stripe->create_customer({ email => 'bob@foo.com' });

=head2 update_customer

    update_customer($id, $data)

Updates a customer.
Returns the updated customer.

Example:

    $customer = $stripe->update_customer($id, { description => 'foo' });

=head2 get_customers

    get_customers(query => $query)

Returns a list of customers.
The query param is optional.

=head2 next

    next($collection)

Returns the next page of results for the given collection.

Example:

    my $customers = $stripe->get_customers;
    ...
    while ($customers = $stripe->next($customers)) {
        ...
    }

=head2 create_card

    create_card($data, customer_id => 'cus_123')

=head2 get_charge

    get_charge($id, query => { expand => ['customer'] })

Returns the charge for the given id. The optional :$query parameter allows
passing query arguments. Passing an arrayref as a query param value will expand
it into Stripe's expected array format.

=head2 create_charge

    create_charge($data)

Creates a charge.

=head2 capture_charge

    capture_charge($id, data => $data)

Captures the charge with the given id.
The data param is optional.

=head2 refund_charge

    refund_charge($id, data => $data)

Refunds the charge with the given id.
The data param is optional.

=head2 refund_app_fee

    refund_app_fee($fee_id, data => $data)

Refunds the application fee with the given id.
The data param is optional.

=head2 update_charge

    update_charge($id, $data)

Updates an existing charge object.

=head2 add_source

    add_source($cust_id, $card_data)

Adds a new funding source (credit card) to an existing customer.

=head2 get_token

    get_token($id)

=head2 create_token

    create_token($data)

=head2 get_account

    get_account($id)

=head2 create_account

    create_account($data)

=head2 update_account

    update_account($id, data => $data)

=head2 upload_identity_document

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

=head2 add_bank

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

=head2 update_bank

    update_bank($id, account_id => $account_id, data => $data)

=head2 create_transfer

    create_transfer($data)

=head2 get_transfer

    get_transfer($id)

=head2 get_transfers

    get_transfers(query => $query)

=head2 update_transfer

    update_transfer($id, data => $data)

=head2 cancel_transfer

    cancel_transfer($id)

=head2 create_reversal

Reverses an existing transfer.

L<Stripe Documentation|https://stripe.com/docs/api/python#transfer_reversals>

Example:

    $ws_stripe->create_reversal(
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

=head2 get_balance

    get_balance()

=head2 get_bitcoin_receivers

    get_bitcoin_receivers()

=head2 create_bitcoin_receiver

    create_bitcoin_receiver($data)

Example:

    my $receiver = $stripe->create_bitcoin_receiver({
        amount   => 100,
        currency => 'usd',
        email    => 'bob@tilt.com',
    });

=head2 get_bitcoin_receiver

    get_bitcoin_receiver($id)

=cut

1;
