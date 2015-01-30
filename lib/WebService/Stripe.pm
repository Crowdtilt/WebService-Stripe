package WebService::Stripe;
use Moo;
with 'WebService::Client';

# VERSION

use Carp qw(croak);
use Method::Signatures;
use constant { MARKETPLACES_MIN_VERSION => '2014-11-05' };

has api_key => (
    is       => 'ro',
    required => 1,
);

has version => (
    is      => 'ro',
    default => MARKETPLACES_MIN_VERSION,
);

has request_scrubber => (
    is      => 'ro',
    default => sub {
        my ($req) = @_;
        return undef unless $req->method =~ qr/GET|HEAD|OPTIONS/;
        return $req;
    },
);

has response_scrubber => (
    is      => 'ro',
    default => sub {
        my ($res) = @_;
        my $copy = $res->clone;
        $copy->header('Authorization' => undef);
        return $copy;
    },
);

has '+base_url' => ( default => 'https://api.stripe.com' );

has '+content_type' => ( default => 'application/x-www-form-urlencoded' );

method BUILD(@args) {
    $self->ua->default_headers->authorization_basic( $self->api_key, '' );
    $self->ua->default_header( 'Stripe-Version' => $self->version );
}

method next(HashRef $thing, HashRef :$query) {
    $query ||= {};
    return undef unless $thing->{has_more};
    my $starting_after = $thing->{data}[-1]{id} or return undef;
    return $self->get( $thing->{url},
        { %$query, starting_after => $starting_after } );
}

method create_customer(Maybe[HashRef] $data, :$headers) {
    return $self->post( "/v1/customers", $data, headers => $headers );
}

method get_balance(:$headers) {
    return $self->get( "/v1/balance", {}, headers => $headers );
}

method get_customer(Str $id, :$headers) {
    return $self->get( "/v1/customers/$id", {}, headers => $headers );
}

method update_customer(Str $id, HashRef $data, :$headers) {
    return $self->post( "/v1/customers/$id", $data, headers => $headers );
}

method get_customers(HashRef :$query, :$headers) {
    return $self->get( "/v1/customers", $query, headers => $headers );
}

method create_card(HashRef $data, :$customer_id!, :$headers) {
    return $self->post(
        "/v1/customers/$customer_id/cards", $data, headers => $headers );
}

method get_charge(Str $id, :$headers) {
    return $self->get( "/v1/charges/$id", {}, headers => $headers );
}

method create_charge(HashRef $data, :$headers) {
    return $self->post( "/v1/charges", $data, headers => $headers );
}

method capture_charge(Str $id, HashRef :$data, :$headers) {
    return $self->post( "/v1/charges/$id/capture", $data, headers => $headers );
}

method refund_charge(Str $id, HashRef :$data, :$headers) {
    return $self->post( "/v1/charges/$id/refunds", $data, headers => $headers );
}

method create_token(HashRef $data, :$headers) {
    return $self->post( "/v1/tokens", $data, headers => $headers );
}

method get_token(Str $id, :$headers) {
    return $self->get( "/v1/tokens/$id", {}, headers => $headers );
}

method create_account(HashRef $data, :$headers) {
    return $self->post( "/v1/accounts", $data, headers => $headers );
}

method get_account(Str $id, :$headers) {
    return $self->get( "/v1/accounts/$id", {}, headers => $headers );
}

method update_account(Str $id, HashRef :$data!, :$headers) {
    return $self->post( "/v1/accounts/$id", $data, headers => $headers );
}

method add_bank(HashRef $data, Str :$account_id!, :$headers) {
    return $self->post(
        "/v1/accounts/$account_id/bank_accounts", $data, headers => $headers );
}

method update_bank(Str $id, Str :$account_id!, HashRef :$data!, :$headers) {
    return $self->post( "/v1/accounts/$account_id/bank_accounts/$id", $data,
        headers => $headers );
}

method delete_bank(Str $id, Str :$account_id!, :$headers) {
    return $self->delete(
        "/v1/accounts/$account_id/bank_accounts/$id", headers => $headers );
}

method get_banks(Str :$account_id!, :$headers) {
    return $self->get(
        "/v1/accounts/$account_id/bank_accounts", {}, headers => $headers );
}

method create_transfer(HashRef $data, :$headers) {
    return $self->post( "/v1/transfers", $data, headers => $headers );
}

method get_transfer(Str $id, :$headers) {
    return $self->get( "/v1/transfers/$id", {}, headers => $headers );
}

method get_transfers(HashRef :$query, :$headers) {
    return $self->get( "/v1/transfers", $query, headers => $headers );
}

method update_transfer(Str $id, HashRef :$data!, :$headers) {
    return $self->post( "/v1/transfers/$id", $data, headers => $headers );
}

method cancel_transfer(Str $id, :$headers) {
    return $self->post("/v1/transfers/$id/cancel", undef, headers => $headers);
}

around _log_request => sub {
    my ($orig, $self, $req) = @_;
    if (my $loggable = $self->request_scrubber($req)) {
        return $self->$orig($loggable);
    }
};

around _log_response => sub {
    my ($orig, $self, $res) = @_;
    if (my $loggable = $self->response_scrubber($res)) {
        return $self->$orig($loggable);
    }
};

# ABSTRACT: Stripe API bindings

=head1 SYNOPSIS

    my $stripe = WebService::Stripe->new(
        api_key => 'secret',
        version => '2014-11-05', # optional
    );
    my $customer = $stripe->get_customer('cus_57eDUiS93cycyH');

=head1 HEADERS

WebService::Stripe supports passing custom headers to any API request by passing a hash of header values as the optional C<headers> named parameter:

    $stripe->create_charge({ ... }, headers => { stripe_account => "acct_123" })

Note that header names are normalized: C<foo_bar>, C<Foo-Bar>, and C<foo-bar> are equivalent.

Three headers stand out in particular:

=over

=item Stripe-Version

This indicates the version of the Stripe API to use. If not given, we default to C<2014-11-05>, which is the earliest version of the Stripe API to support marketplaces.

=item Stripe-Account

This specifies the ID of the account on whom the request is being made. It orients the Stripe API around that account, which may limit what records or actions are able to be taken. For example, a `get_card` request will fail if given the ID of a card that was not associated with the account.

=item Idempotency-Key

All POST methods support idempotent requests through setting the value of an Idempotency-Key header. This is useful for preventing a request from being executed twice, e.g. preventing double-charges. If two requests are issued with the same key, only the first results in the creation of a resource; the second returns the latest version of the existing object.

This feature is in ALPHA and subject to change without notice. Contact Stripe to confirm the latest behavior and header name.

=back

=head1 METHODS

=head2 get_customer

    get_customer($id)

Returns the customer for the given id.

=head2 create_customer

    create_customer($data)

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

    get_charge($id)

Returns the charge for the given id.

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

=head2 get_balance

    get_balance()

=cut

1;
