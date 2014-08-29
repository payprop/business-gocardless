package Business::GoCardless;

$Business::GoCardless::VERSION = '0.01_01';

use Moo;
use Carp qw/ confess /;
use Business::GoCardless::Client;

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

1;

# vim: ts=4:sw=4:et
