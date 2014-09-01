package Business::GoCardless::Resource;

use Moo;
use Business::GoCardless::Exception;

has endpoint => (
    is       => 'ro',
    default  => sub {
        my ( $self ) = @_;
        my ( $class ) = lc( ( split( ':',ref( $self ) ) )[-1] );
        return "/${class}s/%s";
    },
);

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::GoCardless::Client" )
            if ref $_[0] ne 'Business::GoCardless::Client'
    },
    required => 1,
);

sub save_data {
    my ( $self,$data ) = @_;

    if ( $self->persisted ) {
        Business::GoCardless::Exception->throw({
            message => ref( $self ) . " cannot be updated"
        }) if ! $self->updatable;
    } else {
        Business::GoCardless::Exception->throw({
            message => ref( $self ) . " cannot be created"
        }) if ! $self->creatable;
    }

    my $method = $self->persisted ? 'put' : 'post';
    my $path   = sprintf( $self->endpoint,$self->id );
    my $res    = $self->client->send( "api_${method}",$path,$data );

}

sub find_with_client {
    my ( $self ) = @_;

    my $path = sprintf( $self->endpoint,$self->id );
    my $data = $self->client->api_get( $path );

    return $self->new(
        client => $self->client,
        %{ $data },
    );
}

sub _operation {
    my ( $self,$verb ) = @_;
    $self->client->api_post( sprintf( $self->endpoint,$self->id ) . "/$verb" );
}

1;

# vim: ts=4:sw=4:et
