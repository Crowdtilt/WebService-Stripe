package WebService::Stripe;
use Moo;
with 'WebService::Client';

# VERSION

use Carp qw(croak);
use Method::Signatures;

has api_key => (
    is       => 'ro',
    required => 1,
);

has version => (
    is      => 'ro',
    default => '2014-11-05',
);

has '+base_url' => ( default => 'https://api.stripe.com' );

has '+content_type' => ( default => 'application/x-www-form-urlencoded' );

method BUILD(@args) {
    $self->ua->default_headers->authorization_basic( $self->api_key, '' );
    $self->ua->default_header( 'Stripe-Version' => '2014-11-05' );
}

method next(HashRef $thing!, HashRef :$query) {
    $query ||= {};
    return undef unless $thing->{has_more};
    my $starting_after = $thing->{data}[-1]{id} or return undef;
    return $self->get( $thing->{url},
        { %$query, starting_after => $starting_after } );
}

method create_customer(HashRef $data={}) {
    return $self->post( "/v1/customers", $data );
}

method get_customer(Str $id) {
    return $self->get( "/v1/customers/$id" );
}

method update_customer(Str $id, HashRef $data) {
    return $self->post( "/v1/customers/$id", $data );
}

method get_customers(HashRef :$query) {
    $query ||= {};
    return $self->get( "/v1/customers", $query );
}

method create_card(HashRef $data, :$customer_id!) {
    return $self->post( "/v1/customers/$customer_id/cards", $data );
}

method create_charge(HashRef $data, :$stripe_account) {
    my $headers = {
        ( stripe_account => $stripe_account ) x!! $stripe_account,
    };
    return $self->post( "/v1/charges", $data, headers => $headers );
}

method create_token(HashRef $data, :$stripe_account) {
    my $headers = {
        ( stripe_account => $stripe_account ) x!! $stripe_account,
    };
    return $self->post( "/v1/tokens", $data, headers => $headers );
}

# ABSTRACT: Stripe API bindings

=head1 SYNOPSIS

    my $stripe = WebService::Stripe->new(
        api_key => 'secret',
        version => '2014-11-05', # optional
    );
    my $customer = $stripe->get_customer('cus_57eDUiS93cycyH');

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

    my $customers = $s->get_customers;
    ...
    while ($customers = $s->next($customers)) {
        ...
    }

=head2 create_card

    create_card($data, customer_id => 'cus_123')
    create_card($data, customer => $customer)

=head2 create_charge

    create_charge($data)

=head2 create_token

    create_token($data)

=cut

1;
