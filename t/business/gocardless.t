#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::MockObject;

# soft requirements of Business::GoCardless::Client
# "soft" in that they're not required => 1 but must
# be set in the ENV var if not passed to constructor
$ENV{GOCARDLESS_APP_ID}      = 'foo';
$ENV{GOCARDLESS_APP_SECRET}  = 'bar';
$ENV{GOCARDLESS_MERCHANT_ID} = 'baz';

# this makes Business::GoCardless::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{GOCARDLESS_DEV_TESTING} = 1;

use_ok( 'Business::GoCardless' );
isa_ok(
    my $GoCardless = Business::GoCardless->new(
        token       => 'MvYX0i6snRh/1PXfPoc6',
        merchant_id => 'MID',
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

# monkey patching LWP here to make this test work without
# having to actually hit the endpoints or use credentials
no warnings 'redefine';
no warnings 'once';
my $mock = Test::MockObject->new;
$mock->mock( 'is_success',sub { 1 } );
*LWP::UserAgent::request = sub { $mock };

test_bill( $GoCardless,$mock );
test_merchant( $GoCardless,$mock );

done_testing();

sub test_bill {

    my ( $GoCardless,$mock ) = @_;

    note( "Bill" );
    like(
        my $new_bill_url = $GoCardless->new_bill_url(
            amount       => 100,
            name         => "Test Bill",
            description  => "Test Bill for testing",
            redirect_uri => "http://localhost/success",
            cancel_uri   => "http://localhost/cancel",
            state        => "id_9SX5G36",
            user         => {
                first_name       => "Lee",
            }
        ),
        qr!https://gocardless\.com/connect/bills/new\?bill%5Bamount%5D=100&bill%5Bcancel_uri%5D=http%3A%2F%2Flocalhost%2Fcancel&bill%5Bdescription%5D=Test%20Bill%20for%20testing&bill%5Bmerchant_id%5D=baz&bill%5Bname%5D=Test%20Bill&bill%5Bredirect_uri%5D=http%3A%2F%2Flocalhost%2Fsuccess&bill%5Bstate%5D=id_9SX5G36&bill%5Buser%5D%5Bfirst_name%5D=Lee&cancel_uri=http%3A%2F%2Flocalhost%2Fcancel&client_id=foo&nonce=.*?&redirect_uri=http%3A%2F%2Flocalhost%2Fsuccess&signature=.*?&timestamp=\d{4}-\d{2}-\d{2}T\d{2}%3A\d{2}%3A\d{2}Z!,
        '->new_bill_url returns a url'
    );

    $mock->mock( 'content',sub { _bill_json() } );
    my $Bill = $GoCardless->confirm_resource(
        resource_id   => 'foo',
        resource_type => 'bill',
    );

    cmp_deeply(
        $Bill,
        _bill_obj(),
        '->confirm_resource returns a Business::GoCardless::Bill object'
    );

    my $i = 0;

    $mock->mock(
        'content',
        sub {
            # first time return a merchant object, next time a list of bills
            $i++
                ? '[' . _bill_json() . ',' . _bill_json() . ']'
                : _merchant_json()
        }
    );

    my @bills = $GoCardless->bills;

    cmp_deeply(
        \@bills,
        [ _bill_obj(),_bill_obj() ],
        '->bills returns an array of Business::GoCardless::Bill objects'
    );

    $mock->mock( 'content',sub { _bill_json() } );
    $Bill = $GoCardless->bill( '123ABCD' );

    cmp_deeply(
        $Bill,
        _bill_obj(),
        '->bill returns a Business::GoCardless::Bill object'
    );

    cmp_deeply(
        $Bill->retry,
        _bill_obj(),
        '->retry returns a Business::GoCardless::Bill object'
    );

    $mock->mock( 'content',sub { _bill_json( 'cancelled' ) } );

    cmp_deeply(
        $Bill = $Bill->cancel,
        _bill_obj( 'cancelled' ),
        '->cancel returns a Business::GoCardless::Bill object'
    );

    ok( $Bill->cancelled,'bill is cancelled' );

    $mock->mock( 'content',sub { _bill_json( 'refunded' ) } );

    cmp_deeply(
        $Bill = $Bill->refund,
        _bill_obj( 'refunded' ),
        '->refund returns a Business::GoCardless::Bill object'
    );

    ok( $Bill->refunded,'bill is refunded' );
}

sub test_merchant {

    my ( $GoCardless,$mock ) = @_;

    note( "Merchant" );

    $mock->mock( 'content',sub { _merchant_json() } );
    cmp_deeply(
        my $Merchant = $GoCardless->merchant,
        _merchant_obj(),
        '->merchant returns a Business::GoCardless::Merchant object',
    );
}

sub _merchant_json {

    return qq{{
  "id":"06Z06JWQW1",
  "name":"Company Ltd",
  "description":"We do stuff.",
  "created_at":"2014-01-22T10:27:42Z",
  "first_name":"Lee",
  "last_name":"Johnson",
  "email":"lee\@foo.com",
  "uri":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1",
  "balance":"0.0",
  "pending_balance":"0.0",
  "next_payout_date":null,
  "next_payout_amount":null,
  "hide_variable_amount":false,
  "sub_resource_uris":{
    "users":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/users",
    "bills":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/bills",
    "pre_authorizations":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/pre_authorizations",
    "subscriptions":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/subscriptions",
    "payouts":"https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/payouts"
  },
  "gbp_balance":"0.0",
  "eur_balance":"0.0",
  "gbp_pending_balance":"0.0",
  "eur_pending_balance":"0.0"
}};
}

sub _merchant_obj {

    return bless(
        {
            'balance' => '0.0',
            'client'  => bless(
                {
                    'api_path'    => '/api/v1',
                    'app_id'      => 'foo',
                    'app_secret'  => 'bar',
                    'base_url'    => 'https://gocardless.com',
                    'merchant_id' => 'baz',
                    'token'       => 'MvYX0i6snRh/1PXfPoc6'
                },
                'Business::GoCardless::Client'
            ),
            'created_at'           => '2014-01-22T10:27:42Z',
            'description'          => 'We do stuff.',
            'email'                => 'lee@foo.com',
            'endpoint'             => '/merchants/%s',
            'eur_balance'          => '0.0',
            'eur_pending_balance'  => '0.0',
            'first_name'           => 'Lee',
            'gbp_balance'          => '0.0',
            'gbp_pending_balance'  => '0.0',
            'hide_variable_amount' => bless( do { \( my $o = 0 ) }, 'JSON::PP::Boolean' ),
            'id'                   => '06Z06JWQW1',
            'last_name'            => 'Johnson',
            'name'                 => 'Company Ltd',
            'next_payout_amount'   => undef,
            'next_payout_date'     => undef,
            'pending_balance'      => '0.0',
            'sub_resource_uris'    => {
                'bills'   => 'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/bills',
                'payouts' => 'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/payouts',
                'pre_authorizations' =>
                    'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/pre_authorizations',
                'subscriptions' =>
                    'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/subscriptions',
                'users' => 'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1/users'
            },
            'uri' => 'https://sandbox.gocardless.com/api/v1/merchants/06Z06JWQW1'
        },
        'Business::GoCardless::Merchant'
        );
}

sub _bill_json {

    my ( $status ) = @_;

    $status //= 'pending';

    return qq{{
  "amount": "44.0",
  "gocardless_fees": "0.44",
  "partner_fees": "0",
  "currency": "GBP",
  "created_at": "2014-08-20T21:41:25Z",
  "description": "Month 2 payment",
  "id": "123ABCD",
  "name": "Bill 2 for Subscription description",
  "paid_at":  null,
  "status": "$status",
  "merchant_id": "06Z06JWQW1",
  "user_id": "FIVWCCVEST6S4D",
  "source_type": "ad_hoc_authorization",
  "source_id": "YH1VEVQHYVB1UT",
  "uri": "https://gocardless.com/api/v1/bills/123ABCD",
  "can_be_retried": false,
  "payout_id": null,
  "is_setup_fee": false,
  "charge_customer_at": "2014-09-01"
}};
}

sub _bill_obj {

    my ( $status ) = @_;

    $status //= 'pending';

    return bless({
        'amount'             => '44.0',
        'can_be_retried'     => bless(
            do { \( my $o = 0 ) },
            'JSON::PP::Boolean'
        ),
        'charge_customer_at' => '2014-09-01',
        'client'             => bless(
            {
                'api_path'    => '/api/v1',
                'app_id'      => 'foo',
                'app_secret'  => 'bar',
                'base_url'    => 'https://gocardless.com',
                'merchant_id' => 'baz',
                'token'       => 'MvYX0i6snRh/1PXfPoc6'
            },
            'Business::GoCardless::Client'
        ),
        'created_at'      => '2014-08-20T21:41:25Z',
        'currency'        => 'GBP',
        'description'     => 'Month 2 payment',
        'endpoint'        => '/bills/%s',
        'gocardless_fees' => '0.44',
        'id'              => '123ABCD',
        'is_setup_fee'    => bless(
             do { \( my $o = 0 ) },
            'JSON::PP::Boolean'
        ),
        'merchant_id'     => '06Z06JWQW1',
        'name'            => 'Bill 2 for Subscription description',
        'paid_at'         => undef,
        'partner_fees'    => '0',
        'payout_id'       => undef,
        'source_id'       => 'YH1VEVQHYVB1UT',
        'source_type'     => 'ad_hoc_authorization',
        'status'          => $status,
        'user_id'         => 'FIVWCCVEST6S4D',
        'uri'             => 'https://gocardless.com/api/v1/bills/123ABCD',
    },'Business::GoCardless::Bill'
    );
}

# vim: ts=4:sw=4:et
