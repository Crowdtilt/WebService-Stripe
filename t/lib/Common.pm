package t::lib::Common;

use v5.14;
use Exporter qw(import);
use Test::More import => [qw(plan)];
use WebService::Stripe;

our @EXPORT_OK = qw( skip_unless_has_secret stripe );

sub skip_unless_has_secret {
    plan skip_all => 'PERL_STRIPE_TEST_API_KEY is required' unless api_key();
}

sub stripe {
    my %params = @_;
    state $client = WebService::Stripe->new( api_key => api_key(), %params );
    return $client;
}

sub api_key { $ENV{PERL_STRIPE_TEST_API_KEY} }

1;
