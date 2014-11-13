# NAME

WebService::Stripe - Stripe API bindings

# VERSION

version 0.0001

# SYNOPSIS

    my $stripe = WebService::Stripe->new(
        api_key => 'secret',
        version => '2014-11-05', # optional
    );
    my $customer = $stripe->get_customer('cus_57eDUiS93cycyH');

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

    update_customer($id, $data)

Updates a customer.
Returns the updated customer.

Example:

    $customer = $stripe->update_customer($id, { description => 'foo' });

## get\_customers

    get_customers(query => $query)

Returns a list of customers.
The query param is optional.

## next

    next($collection)

Returns the next page of results for the given collection.

Example:

    my $customers = $s->get_customers;
    ...
    while ($customers = $s->next($customers)) {
        ...
    }

# AUTHOR

Naveed Massjouni <naveed@vt.edu>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Tilt, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
