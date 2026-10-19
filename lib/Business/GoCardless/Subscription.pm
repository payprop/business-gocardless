package Business::GoCardless::Subscription;

=head1 NAME

Business::GoCardless::Subscription

=head1 DESCRIPTION

A class for a gocardless subscription, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount
    app_fee
    created_at
    count
    currency
    description
    day_of_month
    earliest_charge_date_after_resume
    expires_at
    end_date
    id
    interval_length
    interval_unit
    interval
    links
    merchant_id
    metadata
    month
    name
    next_interval_start
    parent_plan_paused
    payment_reference
    retry_if_possible
    setup_fee
    start_at
    start_date
    status
    sub_resource_uris
    uri
    user_id
    upcoming_payments

=cut

has [ qw/
    amount
    app_fee
    created_at
    count
    currency
    description
    day_of_month
    earliest_charge_date_after_resume
    expires_at
    end_date
    id
    interval_length
    interval_unit
    interval
    links
    merchant_id
    metadata
    month
    name
    next_interval_start
    parent_plan_paused
    payment_reference
    retry_if_possible
    setup_fee
    start_at
    start_date
    status
    sub_resource_uris
    uri
    user_id
    upcoming_payments
/ ] => (
    is => 'rw',
);

=head1 Operations on a subscription

    cancel

    $Subscription->cancel

Cancels a subscription.

=cut

sub cancel {
    my ( $self ) = @_;

    if ( $self->client->api_version > 1 ) {
        return $self->_operation( undef,'api_post',undef,'actions/cancel' );
    } else {
        return $self->_operation( 'cancel','api_put' );
    }
}

=head1 Status checks on a subscription

    pending_customer_approval
    customer_approval_denied
    inactive
    active
    finished
    cancelled
    paused
    expired

    if ( $Subscription->active ) {
        ...
    }

=cut

sub pending_customer_approval { return shift->status eq 'pending_customer_approval' }
sub customer_approval_denied  { return shift->status eq 'customer_approval_denied' }
sub inactive  { return shift->status eq 'inactive' }
sub active    { return shift->status eq 'active' }
sub finished  { return shift->status eq 'finished' }
sub cancelled { return shift->status eq 'cancelled' }
sub paused    { return shift->status eq 'paused' }
sub expired   { return shift->status eq 'expired' }

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
