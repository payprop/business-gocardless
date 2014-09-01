#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;

# soft requirements of Business::GoCardless::Client
# "soft" in that they're not required => 1 but must
# be set in the ENV var if not passed to constructor
$ENV{GOCARDLESS_APP_ID}     = 'foo';
$ENV{GOCARDLESS_APP_SECRET} = 'bar';

use_ok( 'Business::GoCardless' );
isa_ok(
    my $GoCardless = Business::GoCardless->new(
        token => 'MvYX0i6snRh/1PXfPoc6',
    ),
    'Business::GoCardless'
);

can_ok(
    $GoCardless,
    qw/
        token
        client_details
        client
        bill
    /,
);

cmp_deeply( $GoCardless->client_details,{},'client_details' );
isa_ok( $GoCardless->client,'Business::GoCardless::Client' );

done_testing();

# vim: ts=4:sw=4:et
