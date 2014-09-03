package Business::GoCardless::Subscription;

use Moo;
extends 'Business::GoCardless::Resource';

use Business::GoCardless::Exception;

has [ qw/
    amount
    created_at
    currency
    description
    expires_at
    id
    interval_length
    interval_unit
    merchant_id
    name
    next_interval_start
    setup_fee
    start_at
    status
    sub_resource_uris
    uri
    user_id
/ ] => (
    is => 'rw',
);

sub cancel { shift->_operation( 'cancel','api_put' ); }

sub inactive  { return shift->status eq 'inactive' }
sub active    { return shift->status eq 'active' }
sub cancelled { return shift->status eq 'cancelled' }
sub expired   { return shift->status eq 'expired' }

1;

# vim: ts=4:sw=4:et
