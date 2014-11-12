package WebService::Stripe;
use Moo;
with 'WebService::Client';

# VERSION

use Method::Signatures;

has api_key => (
    is       => 'ro',
    required => 1,
);

has version => (
    is      => 'ro',
    default => '2014-11-05',
);

has '+base_url' => ( default => 'https://api.stripe.com/v1' );

has '+content_type' => ( default => 'application/x-www-form-urlencoded' );

method BUILD(@args) {
    $self->ua->default_headers->authorization_basic( $self->api_key, '' );
    $self->ua->default_header( 'Stripe-Version' => '2014-11-05' );
}

method create_customer(HashRef $cust) {
    return $self->post( "/customers", $cust );
}

method get_customer(Str $id!) {
    return $self->get( "/customers/$id" );
}

method update_customer(Str $id!, HashRef $data!) {
    return $self->post( "/customers/$id", $data );
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

=cut

1;
