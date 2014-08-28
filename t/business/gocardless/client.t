#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;

use_ok( 'Business::GoCardless::Client' );
isa_ok(
    my $Client = Business::GoCardless::Client->new(
        token      => 'MvYX0i6snRh/1PXfPoc6',
        app_id     => 'some application',
        app_secret => 'setec astronomy'
    ),
    'Business::GoCardless::Client'
);

can_ok(
    $Client,
    qw/
        base_url
        api_path
    /,
);

done_testing();

# vim: ts=4:sw=2:et
