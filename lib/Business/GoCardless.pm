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

=head1 METHODS

=head2 new_bill_url

=head2 confirm_resource

=head2 bill

=head2 bills

=cut

# Bill methods
sub new_bill_url {
    my ( $self,%params ) = @_;
    return $self->client->new_bill_url( \%params );
}

sub confirm_resource {
    my ( $self,%params ) = @_;
    return $self->client->confirm_resource( \%params );
}

sub bill {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Bill' );
}

sub bills {
    my ( $self,$id ) = @_;
    return Business::GoCardless::Merchant->new(
        client => $self->client,
        id     => $self->client->merchant_id,
    )->bills;
}

# Merchant methods

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
