#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use FindBin qw/ $Bin /;

use Business::GoCardless;

my $GoCardless = Business::GoCardless->new(
    token          => 'foo',
    client_details => {
        base_url   => 'http://localhost:3000',
    },
);

isa_ok( $GoCardless,'Business::GoCardless' );

done_testing();
