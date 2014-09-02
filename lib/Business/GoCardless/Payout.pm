package Business::GoCardless::Payout;

use Moo;
extends 'Business::GoCardless::Resource';

use Business::GoCardless::Exception;

has [ qw/
    amount
    app_ids
    bank_reference
    created_at
    id
    paid_at
    transaction_fees
/ ] => (
    is => 'rw',
);

1;

# vim: ts=4:sw=4:et
