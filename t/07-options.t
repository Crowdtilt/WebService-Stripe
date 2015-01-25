use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe);

skip_unless_has_secret;

my $acct = stripe->create_account({
    managed => 'true',
    country => 'CA',
});
my $cust = stripe->create_customer(undef);
my $card = stripe->create_card({
    'card[number]'    => '5105105105105100',
    'card[exp_month]' => 12,
    'card[exp_year]'  => 2020,
}, customer_id => $cust->{id});

subtest 'Use idempotency_key to prevent duplicate charges' => sub {
    my $key = rand(1000) . {} . [];
    my %opts = (opts => { idempotency_key => $key });
    my $charge_params = {
        amount      => 1000,
        card        => $card->{id},
        currency    => 'USD',
        customer    => $cust->{id},
        capture     => 'true',
        description => 'foo',
    };
    my $ch1 = stripe->create_charge($charge_params, %opts);
    my $ch2 = stripe->create_charge($charge_params, %opts);
    is $ch1->{id} => $ch2->{id},
        '... Charged only once';
};

subtest 'Use stripe_account to associate customers to an account' => sub {
    my %opts = (opts => { stripe_account => $acct->{id} });
    ok exception {
        stripe->create_charge({
            amount   => 1000,
            card     => $card->{id},
            currency => 'USD',
            customer => $cust->{id},
            capture  => 'true',
        }, %opts);
    },
        '... Failed charging customer not associated with account';

    my $acct_cust = stripe->create_customer(undef, %opts);
    my $acct_card_tok = stripe->create_token({
        'card[number]'    => '5105105105105100',
        'card[exp_month]' => 12,
        'card[exp_year]'  => 2020,
    }, %opts);
    my $acct_card = stripe->create_card({
        card => $acct_card_tok->{id},
    }, customer_id => $acct_cust->{id}, %opts);
    ok stripe->create_charge({
        amount   => 1000,
        card     => $acct_card->{id},
        currency => 'USD',
        customer => $acct_cust->{id},
        capture  => 'true',
    }, %opts),
        '... Able to charge customer associated with Account';
};

done_testing;
