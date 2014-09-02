package Business::GoCardless;

$Business::GoCardless::VERSION = '0.01_01';

=head1 NAME

Business::GoCardless

=head1 VERSION

0.01_01

=head1 DESCRIPTION

=head1 SYNOPSIS

=cut

use Moo;
use Carp qw/ confess /;

use Business::GoCardless::Bill;
use Business::GoCardless::Client;
use Business::GoCardless::Merchant;
use Business::GoCardless::Payout;
use Business::GoCardless::Subscription;

=head1 ATTRIBUTES

=head2 token

=cut

has token => (
    is       => 'ro',
    required => 1,
);

has client_details => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a hashref" )
            if ref( $_[0] ) ne 'HASH';
    },
    required => 0,
    lazy     => 1,
    default  => sub { return {} },
);

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::GoCardless::Client" )
            if ref $_[0] ne 'Business::GoCardless::Client'
    },
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;

        return Business::GoCardless::Client->new(
            %{ $self->client_details },
            token => $self->token,
        );
    },
);

=head1 Bill

=head2 new_bill_url

=head2 confirm_bill

=head2 bill

=head2 bills

=cut

sub new_bill_url {
    my ( $self,%params ) = @_;
    return $self->client->new_bill_url( \%params );
}

sub confirm_bill {
    my ( $self,$id ) = @_;
    return $self->confirm_resource(
        resource_id   => $id,
        resource_type => 'bill',
    );
}

sub bill {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Bill' );
}

sub bills {
    my ( $self,$merchant_id ) = @_;
    return $self->merchant( $merchant_id )->bills;
}

=head1 Merchant

=head2 merchant

=head2 payouts

=cut

sub merchant {
    my ( $self,$merchant_id ) = @_;

    $merchant_id //= $self->client->merchant_id;
    return Business::GoCardless::Merchant->new(
        client => $self->client,
        id     => $merchant_id
    );
}

sub payouts {
    my ( $self,$merchant_id ) = @_;
    return $self->merchant( $merchant_id )->payouts;
}

=head1 Payout

=head2 payout

=cut

sub payout {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Payout' );
}

=head1 PreAuthorization

=head2 new_pre_authorization_url

=head2 confirm_pre_authorization

=head2 pre_authorization

=head2 pre_authorizations

=cut

sub new_pre_authorization_url {
    my ( $self,%params ) = @_;
    return $self->client->new_pre_authorization_url( \%params );
}

sub confirm_pre_authorization {
    my ( $self,$id ) = @_;
    return $self->confirm_resource(
        resource_id   => $id,
        resource_type => 'pre_authorization',
    );
}

sub pre_authorization {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'PreAuthorization' );
}

sub pre_authorizations {
    my ( $self,$merchant_id ) = @_;
    return $self->merchant( $merchant_id )->pre_authorizations;
}

=head1 Subscription

=head2 new_subscription_url

=head2 confirm_subscription

=head2 subscription

=head2 subscriptions

=cut

sub new_subscription_url {
    my ( $self,%params ) = @_;
    return $self->client->new_subscription_url( \%params );
}

sub confirm_subscription {
    my ( $self,$id ) = @_;
    return $self->confirm_resource(
        resource_id   => $id,
        resource_type => 'subscription',
    );
}

sub subscription {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Subscription' );
}

sub subscriptions {
    my ( $self,$merchant_id ) = @_;
    return $self->merchant( $merchant_id )->subscriptions;
}

=head1 Common

=head2 confirm_resource

=cut

sub confirm_resource {
    my ( $self,%params ) = @_;
    return $self->client->confirm_resource( \%params );
}

sub _generic_find_obj {
    my ( $self,$id,$class ) = @_;
    $class = "Business::GoCardless::$class";
    my $obj = $class->new(
        id     => $id,
        client => $self->client
    );
    return $obj->find_with_client;
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=cut

1;

# vim: ts=4:sw=4:et
