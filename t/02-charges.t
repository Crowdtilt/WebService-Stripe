use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe);
use JSON;

skip_unless_has_secret;

my $customer = stripe->create_customer({ description => 'foo' });
my $card = stripe->create_card(
    {
        'card[number]'    => '5105105105105100',
        'card[exp_month]' => 12,
        'card[exp_year]'  => 2020,
    },
    customer_id => $customer->{id}
);

subtest 'create charge' => sub {
    my $charge = stripe->create_charge({
        amount      => 1000,
        card        => $card->{id},
        currency    => 'USD',
        customer    => $customer->{id},
        capture     => JSON::true,
        description => 'foo',
    });
    cmp_deeply $charge,
        TD->superhashof({
            amount      => 1000,
            description => 'foo',
            captured    => TD->str('true'),
        }),
        'created charge';
};

subtest 'refund a hold' => sub {
    my $charge = stripe->create_charge({
        amount      => 1000,
        card        => $card->{id},
        currency    => 'USD',
        customer    => $customer->{id},
        capture     => JSON::false,
    });
    cmp_deeply $charge,
        TD->superhashof({ amount => 1000, captured => TD->str('false') }),
        'created hold';
    my $refund = stripe->refund_charge($charge->{id});
    cmp_deeply $refund, TD->superhashof({amount => 1000, id => TD->re('^re')}),
        'created refund';
};

subtest 'refund a debit' => sub {
    my $charge = stripe->create_charge({
        amount      => 1000,
        card        => $card->{id},
        currency    => 'USD',
        customer    => $customer->{id},
        capture     => JSON::true,
    });
    cmp_deeply $charge,
        TD->superhashof({ amount => 1000, captured => TD->str('true') }),
        'created hold';
    my $refund = stripe->refund_charge($charge->{id});
    cmp_deeply $refund, TD->superhashof({amount => 1000, id => TD->re('^re')}),
        'created refund';
};

done_testing;

#method refund_charge(Str $id, HashRef :$data, @rest) {
#    return $self->post( "/v1/charges/$id/refunds", $data, @rest );
#}

