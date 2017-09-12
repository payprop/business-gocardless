#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use JSON qw/ decode_json /;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Webhook::V2' );
isa_ok(
    my $Webhook = Business::GoCardless::Webhook::V2->new(
        client => Business::GoCardless::Client->new(
            token          => 'foo',
            webhook_secret => 'bar',
        ),
        json => _json_payload(),
        _signature => 'd83ab95b082ac2d0154060fe63530723104d55249b00f1b49019859cbcd51078',
    ),
    'Business::GoCardless::Webhook::V2'
);

can_ok(
    $Webhook,
    qw/
        resource_type
        action
    /,
);

ok( my $events = $Webhook->events,'->events' );
cmp_deeply(
    $events->[2],
    bless( {
        'action' => 'paid_out',
        'client' => bless( {
          'api_version' => 1,
          'base_url' => 'https://gocardless.com',
          'token' => 'foo',
          'user_agent' => ignore(),
          'webhook_secret' => 'bar'
        }, 'Business::GoCardless::Client' ),
        'created_at' => '2017-09-11T14:05:35.461Z',
        'endpoint' => '/events/%s',
        'id' => 'EV789',
        'links' => {
          'parent_event' => 'EV123',
          'payment' => 'PM456',
          'payout' => 'PO123'
        },
        'details' => {
          'cause' => 'payment_paid_out',
          'description' => 'The payment has been paid out by GoCardless.',
          'origin' => 'gocardless'
        },
        'resource_type' => 'payments'
      }, 'Business::GoCardless::Webhook::Event'
    ),
    'more than one event'
);

$Webhook->signature( 'bad signature' );

throws_ok(
    sub { $Webhook->json( _json_payload() ) },
    'Business::GoCardless::Exception',
    '->json checks signature',
);

ok( ! $Webhook->resources,' ... and clears resources if bad' );

done_testing();

sub _json_payload {

    my ( $signature ) = @_;

    $signature //= 'd83ab95b082ac2d0154060fe63530723104d55249b00f1b49019859cbcd51078';

    return qq!{
   "events" : [
      {
         "action" : "paid",
         "created_at" : "2017-09-11T14:05:35.414Z",
         "details" : {
            "cause" : "payout_paid",
            "description" : "GoCardless has transferred the payout to the creditor's bank account.",
            "origin" : "gocardless"
         },
         "id" : "EV123",
         "links" : {
            "payout" : "PO123"
         },
         "metadata" : {},
         "resource_type" : "payouts"
      },
      {
         "action" : "paid_out",
         "created_at" : "2017-09-11T14:05:35.453Z",
         "details" : {
            "cause" : "payment_paid_out",
            "description" : "The payment has been paid out by GoCardless.",
            "origin" : "gocardless"
         },
         "id" : "EV456",
         "links" : {
            "parent_event" : "EV123",
            "payment" : "PM123",
            "payout" : "PO123"
         },
         "metadata" : {},
         "resource_type" : "payments"
      },
      {
         "action" : "paid_out",
         "created_at" : "2017-09-11T14:05:35.461Z",
         "details" : {
            "cause" : "payment_paid_out",
            "description" : "The payment has been paid out by GoCardless.",
            "origin" : "gocardless"
         },
         "id" : "EV789",
         "links" : {
            "parent_event" : "EV123",
            "payment" : "PM456",
            "payout" : "PO123"
         },
         "metadata" : {},
         "resource_type" : "payments"
      }
   ]
}!;
}

# vim: ts=4:sw=4:et
