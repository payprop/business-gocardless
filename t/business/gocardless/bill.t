#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use_ok( 'Business::GoCardless::Bill' );
isa_ok(
    my $Bill = Business::GoCardless::Bill->new,
    'Business::GoCardless::Bill'
);

can_ok(
    $Bill,
    qw/
        endpoint
        amount
        gocardless_fees
        partner_fees
        amount_minus_fees
        currency
        description
        name
        status
        can_be_retried
        can_be_cancelled
        is_setup_fee
        source_id
        source_type
        merchant_id
        user_id
        payout_id
        created_at
        paid_at
        charge_customer_at

        retry
        cancel
        refund
        save
        pending
        paid
        failed
        withdrawn
        refunded
    /,
);

is( $Bill->endpoint,'/bills/%d','endpoint' );

throws_ok(
    sub { $Bill->source( 'bad' ) },
    'Business::GoCardless::Exception',
    'source with bad object throws',
);

is(
    $@->error,
    'source object must be one of PreAuthorization, Subscription',
    ' ... expected error'
);

done_testing();

# vim: ts=4:sw=2:et
