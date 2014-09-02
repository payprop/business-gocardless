package Business::GoCardless::Bill;

use Moo;
use Business::GoCardless::Exception;

extends 'Business::GoCardless::Resource';

has [ qw/
    amount
    amount_minus_fees
    can_be_cancelled
    can_be_retried
    charge_customer_at
    created_at
    currency
    description
    gocardless_fees
    id
    is_setup_fee
    merchant_id
    name
    paid_at
    partner_fees
    payout_id
    source_id
    source_type
    status
    uri
    user_id
/ ] => (
    is => 'rw',
);

sub retry  { shift->_operation( 'retry' ); }
sub cancel { shift->_operation( 'cancel','api_put' ); }
sub refund { shift->_operation( 'refund' ); }

sub pending     { return shift->status eq 'pending' }
sub paid        { return shift->status eq 'paid' }
sub failed      { return shift->status eq 'failed' }
sub chargedback { return shift->status eq 'chargedback' }
sub cancelled   { return shift->status eq 'cancelled' }
sub withdrawn   { return shift->status eq 'withdrawn' }
sub refunded    { return shift->status eq 'refunded' }

1;

# vim: ts=4:sw=4:et
