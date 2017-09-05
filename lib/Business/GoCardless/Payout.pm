package Business::GoCardless::Payout;

=head1 NAME

Business::GoCardless::Payout

=head1 DESCRIPTION

A class for a gocardless payout, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount
    arrival_date
    created_at
    currency
    deducted_fees
    id
    links
    payout_type
    reference
    status

=cut

has [ qw/
    amount
    arrival_date
    created_at
    currency
    deducted_fees
    id
    links
    payout_type
    reference
    status
/ ] => (
    is => 'rw',
);

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
