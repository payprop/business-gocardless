#!perl

use strict;
use warnings;

package Utils::Tester;

use Moo;
with 'Business::GoCardless::Utils';

package main;

use Test::Most;
use Test::Deep;
use Test::Exception;
use MIME::Base64 qw/ decode_base64 /;

use Business::GoCardless::Utils;

my $Utils = Utils::Tester->new;

# examples taken from gocardless API docs:
# https://developer.gocardless.com/#constructing-the-parameter-array
foreach my $test (
    [
        { cars => [ 'BMW','Fiat','VW' ] },
        [
            [ 'cars[]','BMW' ],
            [ 'cars[]','Fiat'],
            [ 'cars[]','VW'  ]
        ],
    ],
    [
        { user => { name => 'Fred', age => 30 } },
        [
            [ 'user[age]' ,'30'   ],
            [ 'user[name]','Fred' ],
        ],
    ],
    [
        { user => { name => 'Fred', cars => ['BMW', 'Fiat'] } },
        [
            [ 'user[cars][]','BMW'  ],
            [ 'user[cars][]','Fiat' ],
            [ 'user[name]'  ,'Fred' ],
        ]
    ],
) {
    cmp_deeply(
        $Utils->flatten_params( $test->[0] ),
        $test->[1],
        'flatten_params',
    );
}

my $test_params = {
    user => {
        age   => 30,
        email => 'fred@example.com',
    }
};

my $app_secret = 
    '5PUZmVMmukNwiHc7V/TJvFHRQZWZumIpCnfZKrVYGpuAdkCcEfv3LIDSrsJ+xOVH';

is(
    $Utils->sign_params( $test_params,$app_secret ),
    '763f02cb9f998a5e06fda2b790bedd503ba1a34fd7cbf9e22f8ce562f73f0470',
    'sign_params'
);

ok(
    $Utils->signature_valid(
        {
            %{ $test_params },
            signature => $Utils->sign_params( $test_params,$app_secret ),
        },
        $app_secret
    ),
    'signature_valid',
);

my ( $time,$rand ) = ( split( '\|',decode_base64( $Utils->generate_nonce ) ) );
ok( length( $time ) == 10,'nonce has time' );
ok( $rand < 257,'nonce rand < 257' );

done_testing();
