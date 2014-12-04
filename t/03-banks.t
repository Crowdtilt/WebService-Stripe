use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe);
use JSON;

skip_unless_has_secret;

subtest 'create bank' => sub {
    my $account = stripe->create_account({
        managed => 'true',
        country => 'CA',
    });
    my $bank = stripe->add_bank(
        {
            'bank_account[country]'        => 'CA',
            'bank_account[currency]'       => 'cad',
            'bank_account[routing_number]' => '00022-001',
            'bank_account[account_number]' => '000123456789',
        },
        account_id => $account->{id},
    );
    cmp_deeply $bank => TD->superhashof({ last4 => 6789 }), 'created bank';
    is stripe->get_account($account->{id})->{bank_accounts}{total_count} => 1;
};

done_testing;
