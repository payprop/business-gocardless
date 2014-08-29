#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;

use_ok( 'Business::GoCardless::Client' );
isa_ok(
    my $Client = Business::GoCardless::Client->new(
        token       => 'MvYX0i6snRh/1PXfPoc6',
        app_id      => 'some application',
        app_secret  => 'setec astronomy',
        merchant_id => '1DJUN3H1I2',
    ),
    'Business::GoCardless::Client'
);

can_ok(
    $Client,
    qw/
        token
        base_url
        api_path
        app_id
        app_secret
        merchant_id
        new_bill_url
        new_limit_url
    /,
);

my $new_url = $Client->new_bill_url({
    amount => 100,
    name   => 'Example payment',
});

like(
    $new_url,
    qr!https://gocardless\.com/connect/bills/new\?bill%5Bamount%5D=100!,
    'new_bill_url',
);

done_testing();

# vim: ts=4:sw=4:et
