package Business::GoCardless::Exception;

use Moo;

with 'Throwable';

has error => (
    is => 'ro',
);

1;

# vim: ts=4:sw=4:et
