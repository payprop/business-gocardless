#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Mandate' );
isa_ok(
    my $Mandate = Business::GoCardless::Mandate->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
			api_version => 2,
        ),
    ),
    'Business::GoCardless::Mandate'
);

can_ok(
    $Mandate,
    qw/
		created_at
        consent_parameters
		id
		links
		metadata
		next_possible_charge_date
		payments_require_approval
		reference
		scheme
		status
    /,
);

is( $Mandate->endpoint,'/mandates/%s','endpoint' );
$Mandate->status( 'active' );

ok( ! $Mandate->pending_customer_approval,'pending_customer_approval' );
ok( ! $Mandate->pending_submission,'pending_submission' );
ok( ! $Mandate->submitted,'submitted' );
ok( $Mandate->active,'active' );
ok( ! $Mandate->failed,'failed' );
ok( ! $Mandate->cancelled,'cancelled' );
ok( ! $Mandate->expired,'expired' );
ok( ! $Mandate->consent_parameters,'consent_parameters' );

$Mandate->id( 123 );
is( $Mandate->uri,'https://api.gocardless.com/mandates/123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
