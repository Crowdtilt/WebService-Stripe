use Test::Modern;
use lib '../WebService-Client/lib';
use t::lib::Common qw(skip_unless_has_secret stripe);

skip_unless_has_secret;

subtest 'basic stuff' => sub {
    my $cust = stripe->create_customer({ description => 'foo' });
    is $cust->{description} => 'foo';

    $cust = stripe->get_customer($cust->{id});
    is $cust->{description} => 'foo';

    $cust = stripe->update_customer($cust->{id}, { description => 'bar' });
    is $cust->{description} => 'bar';

    $cust = stripe->get_customer($cust->{id});
    is $cust->{description} => 'bar';
};

subtest 'create customer with no data' => sub {
    my $cust = stripe->create_customer({ description => 'foo' });
    ok $cust->{id};
};

done_testing;
