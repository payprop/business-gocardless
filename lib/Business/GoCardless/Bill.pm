package Business::GoCardless::Bill;

use Moo;
use Business::GoCardless::Exception;

extends 'Business::GoCardless::Resource';

has [ qw/
    id amount gocardless_fees partner_fees amount_minus_fees
    currency description name status
    can_be_retried can_be_cancelled is_setup_fee
    source_id source_type uri
    merchant_id user_id payout_id
    created_at paid_at charge_customer_at
/ ] => (
    is => 'rw',
);

sub retry  { shift->_operation( 'retry' ); }
sub cancel { shift->_operation( 'cancel','api_get' ); }
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
