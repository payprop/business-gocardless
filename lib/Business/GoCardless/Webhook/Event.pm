package Business::GoCardless::Webhook::Event;

=head1 NAME

Business::GoCardless::Webhook

=head1 DESCRIPTION

A class for gocardless webhook events, extends L<Business::GoCardless::Resource>.
For more details see the gocardless API documentation specific to webhooks:
https://developer.gocardless.com/api-reference/#appendix-webhooks

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';
with 'Business::GoCardless::Utils';

use Business::GoCardless::Exception;

=head1 ATTRIBUTES

    id
    created_at
    action
    resource_type
    links
    details

=cut

has [ qw/
    id
    created_at
    action
    resource_type
    links
/ ] => (
    is       => 'ro',
	required => 1,
);

has [ qw/
    details
/ ] => (
    is       => 'rw',
	required => 0,
);

1;

# vim: ts=4:sw=4:et
