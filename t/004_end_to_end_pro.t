#!perl

use strict;
use warnings;
use utf8;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Business::GoCardless::Pro;
use POSIX qw/ strftime /;

plan skip_all => "GOCARDLESS_ENDTOEND required"
    if ! $ENV{GOCARDLESS_ENDTOEND};

# this is an "end to end" test - it will call the gocardless API
# using the details defined in the ENV variables below. it should
# only be run against the sandbox as it creates (and cancels)
# customers, mandates, payments, and subscriptions
#
# the hosted payment pages that a redirect flow sends the customer to
# are now a javascript app backed by a billing request, so rather than
# filling in a form we play the part of the customer by driving that
# billing request through the API. fulfilling the billing request also
# completes the redirect flow, after which the customer would be sent
# back to the success_redirect_url with the redirect_flow_id
my ( $token,$url,$DEBUG ) = @ENV{qw/
    GOCARDLESS_TOKEN
    GOCARDLESS_URL
    GOCARDLESS_DEBUG
/};

$url //= 'https://api-sandbox.gocardless.com';

BAIL_OUT( "GOCARDLESS_URL must be the sandbox for the end to end test" )
    if $url !~ /sandbox/;

# this makes Business::GoCardless::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{GOCARDLESS_DEV_TESTING} = 1;

my $GoCardless = Business::GoCardless::Pro->new(
    token           => $token,
    # since these are set in %ENV we don't need to pass them
    # but am showing them being passed here for example usage
    client_details  => {
        base_url    => $url,
    },
);

isa_ok( $GoCardless,'Business::GoCardless::Pro' );

# the new_.*_url methods only return the URL, so keep hold of the
# redirect flow that was created so we can act as the customer
my $LastRedirectFlow;
{
    no warnings 'redefine';
    my $orig = \&Business::GoCardless::Client::api_post;
    *Business::GoCardless::Client::api_post = sub {
        my ( $client,$path ) = @_;
        my $data = $orig->( @_ );
        $LastRedirectFlow = $data->{redirect_flows}
            if $path eq '/redirect_flows';
        return $data;
    };
}

my $new_url = $GoCardless->new_bill_url(
    session_token        => 'foo',
    description          => "Test Bill",
    scheme               => 'bacs',
    # not sure about having the amount + currency in the redirect URL (what's
    # to stop user from changing it?) but can't see any other way to be back
    # compat with the Basic API
    success_redirect_url => "http://localhost:3000/rflow/confirm/bill/100/GBP",
);

like( $new_url,qr/^https:\/\//,'->new_bill_url' );
note( $new_url ) if $DEBUG;

isa_ok(
    my $Bill = $GoCardless->confirm_resource(
        %{ _complete_redirect_flow( type => 'bill',amount => 100,currency => 'GBP' ) }
    ),
    'Business::GoCardless::Payment'
);

ok( $Bill->cancel,'cancel bill' );
ok( $Bill->cancelled,'bill cancelled' );

my $NewBill = $GoCardless->bill( $Bill->id );
is( $NewBill->id,$Bill->id,'getting bill with same id gives same bill' );

my $Paginator = $GoCardless->bills(
    limit => 50,
);

note explain $Paginator->info if $DEBUG;

# don't page through the whole sandbox account, just check that we can
# get more than one page (assuming there is more than one page)
my $pages = 0;
while ( my @bills = $Paginator->next ) {
    pass( 'Paginator->next' );
    if ( $DEBUG ) {
        note scalar( @bills );
        note explain [ map { $_->id } @bills ];
    }
    last if ++$pages >= 3;
}

ok( $pages,'Paginator returned at least one page' );

my $new_pre_auth_url = $GoCardless->new_pre_authorization_url(
    session_token        => 'bar',
    description          => "Test Pre Auth",
    scheme               => 'bacs',
    success_redirect_url => "http://localhost:3000/rflow/confirm/pre_auth/100/GBP",
    user => {
          'billing_address1' => '',
          'billing_address2' => '',
          'billing_postcode' => '',
          'billing_town' => '',
          'company_name' => '',
          'country_code' => '',
          'email' => 'foo@hotmail.com',
          'first_name' => 'Lee',
          'last_name' => "Perez de Armiñan",
    }
);

like( $new_pre_auth_url,qr/^https:\/\//,'->new_pre_authorization_url' );

isa_ok(
    my $PreAuthorization = $GoCardless->confirm_resource(
        %{ _complete_redirect_flow( type => 'pre_auth',amount => 100,currency => 'GBP' ) }
    ),
    'Business::GoCardless::RedirectFlow'
);

isa_ok(
    my $Payment = $GoCardless->create_payment(
        amount   => 100,
        currency => 'GBP',
        links    => { mandate => $PreAuthorization->mandate->id },
    ),
    'Business::GoCardless::Payment',
    '->create_payment',
);

note explain $Payment->to_hash if $DEBUG;

throws_ok(
    sub { $Payment->refund },
    'Business::GoCardless::Exception',
    '->refund requires an amount',
);

ok( $Payment->cancel,'->cancel payment' );

ok( $Bill = $PreAuthorization->bill(
    amount   => 100,
    currency => 'GBP',
),'PreAuthorization->bill' );
ok( $Bill->cancel,'->cancel' );

my $Mandate = $PreAuthorization->mandate;
ok( !$Mandate->active,'mandate is not active' );
ok( $Mandate->pending_submission,'mandate is pending_submission' );

isa_ok(
    $Mandate->update( metadata => { foo => "bar" } ),
    'Business::GoCardless::Mandate',
    '->update mandate'
);
cmp_deeply( $Mandate->metadata,{ foo => 'bar' },' ... mandate was updated' );

ok( $Mandate->cancel,'->cancel mandate' );
ok( $Mandate->cancelled,' ... mandate was cancelled' );

# start the subscription next month so the date is always in the future
my ( undef,undef,undef,undef,$mon,$year ) = gmtime;
my $start_at = sprintf( "%04d-%02d-15",
    $mon == 11 ? ( $year + 1901,1 ) : ( $year + 1900,$mon + 2 )
);

my $new_subscription_url = $GoCardless->new_subscription_url(
    session_token        => 'baz',
    description          => "Test Subscription",
    scheme               => 'bacs',
    success_redirect_url => "http://localhost:3000/rflow/confirm/subscription"
        . "/100/GBP/monthly/1/$start_at",
);

like( $new_subscription_url,qr/^https:\/\//,'->new_subscription_url' );

isa_ok(
    my $Subscription = $GoCardless->confirm_resource(
        %{ _complete_redirect_flow(
            type          => 'subscription',
            amount        => 100,
            currency      => 'GBP',
            interval_unit => 'monthly',
            interval      => 1,
            start_at      => $start_at,
        ) }
    ),
    'Business::GoCardless::Subscription'
);

isa_ok(
    $Subscription = $GoCardless->subscription( $Subscription->id ),
    'Business::GoCardless::Subscription'
);

is( $Subscription->start_date,$start_at,'subscription start_date' );
ok( $Subscription->cancel,'->cancel' );
ok( $Subscription->cancelled,' ... subscription was cancelled' );

my $Customer = $GoCardless->customer(
    $GoCardless->mandate( $Mandate->id )->links->{customer}
);
isa_ok( $Customer,'Business::GoCardless::Customer' );
is( $Customer->family_name,'Jøhñsön','->customer (with wide chars)' );

my @users = $GoCardless->users;
my $User = $users[0];
isa_ok( $User,'Business::GoCardless::Customer' );

done_testing();

# act as the customer completing the hosted payment pages for the last
# redirect flow created, returning the params that would be passed to
# the success_redirect_url (and thus to ->confirm_resource)
sub _complete_redirect_flow {
    my ( %params ) = @_;

    my $redirect_flow_id   = $LastRedirectFlow->{id};
    my $billing_request_id = $LastRedirectFlow->{links}{billing_request}
        || BAIL_OUT( "Redirect flow $redirect_flow_id has no billing request" );

    note( "Completing $redirect_flow_id via $billing_request_id" ) if $DEBUG;

    my $Client = $GoCardless->client;

    # sandbox bank details: https://developer.gocardless.com/getting-started/developer-tools/test-bank-details
    foreach my $action (
        [ collect_customer_details => {
            customer => {
                email       => 'lee@example.com',
                given_name  => 'Lee',
                family_name => 'Jøhñsön',
            },
            customer_billing_detail => {
                address_line1 => '1 Test Street',
                city          => 'London',
                postal_code   => 'E1 1AA',
                country_code  => 'GB',
            },
        } ],
        [ collect_bank_account => {
            account_holder_name => 'Lee Jøhñsön',
            account_number      => '55779911',
            branch_code         => '200000',
            country_code        => 'GB',
        } ],
        [ confirm_payer_details => {} ],
        [ fulfil => {} ],
    ) {
        my ( $name,$data ) = @{ $action };

        my $res = $Client->api_post(
            "/billing_requests/$billing_request_id/actions/$name",
            { data => $data },
        );

        note( "$name: $res->{billing_requests}{status}" ) if $DEBUG;
    }

    pass( "customer completed redirect flow ($params{type})" );

    return {
        redirect_flow_id => $redirect_flow_id,
        %params,
    };
}

# vim: ts=4:sw=4:et
