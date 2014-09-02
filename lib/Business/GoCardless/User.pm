package Business::GoCardless::User;

use Moo;
extends 'Business::GoCardless::Resource';

has [ qw/
    created_at
    email
    first_name
    id
    last_name
/ ] => (
    is => 'rw',
);

1;

# vim: ts=4:sw=4:et
