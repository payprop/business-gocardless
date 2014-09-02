package Business::GoCardless::Merchant;

use Moo;
use Business::GoCardless::Exception;

extends 'Business::GoCardless::Resource';

has [ qw/
    id
/ ] => (
    is => 'ro',
);

sub bills  {
    my ( $self ) = @_;

    my $data = $self->client->api_get(
        sprintf( $self->endpoint,$self->id ) . "/bills"
    );

    my @bills = map {
        Business::GoCardless::Bill->new( client => $self->client,%{ $_ } );
    } @{ $data };

    return @bills;
}

1;

# vim: ts=4:sw=4:et
