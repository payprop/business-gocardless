#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use LWP::Simple;
use Business::GoCardless;

use FindBin qw/ $Bin /;

plan skip_all => "GOCARDLESS_ENDTOEND required"
    if ! $ENV{GOCARDLESS_ENDTOEND};

my ( $token,$url,$app_id,$app_secret,$mid ) = @ENV{qw/
    GOCARDLESS_TOKEN
    GOCARDLESS_TEST_URL
    GOCARDLESS_APP_ID
    GOCARDLESS_APP_SECRET
    GOCARDLESS_MERCHANT_ID
/};

$ENV{GOCARDLESS_DEV_TESTING} = 1;

my $GoCardless = Business::GoCardless->new(
    token           => $token // 'DHDEF68S410DTCGNGDNA3DYDD5R',
    client_details  => {
        base_url    => $url        // 'http://localhost:3000',
        app_id      => $app_id     // '6S1YGHNAJRWZ5A9ZXT6XG630FZSJ1YF8PFTNF99',
        app_secret  => $app_secret // '0PSE62M1Z4VDMRB101ZF8BVGCBS3WWY2K5FYJPC',
        merchant_id => $mid        // '1DJUN3H1I2',
    },
);

isa_ok( $GoCardless,'Business::GoCardless' );

=cut
my $new_url = $GoCardless->client->new_bill_url({
    amount       => 100,
    name         => 'Example payment',
    redirect_uri => "http://localhost:3000/merchants/$mid/confirm_resource",
});

note $new_url;

note explain $GoCardless->client->confirm_resource({
    resource_uri  => 'https://sandbox.gocardless.com/api/v1/bills/0PTTCSFZT2',
    resource_id   => '0PTTCSFZT2',
    resource_type => 'bill',
    signature     => 'a133e63223d8de3ae00d2e2c2710d33a0a89394295f06a02fe30a20c6d8603d0',
    #state =>
});
=cut

my @payouts = $GoCardless->payouts;
note explain \@payouts;

done_testing();
