package Business::GoCardless::Resource;

use Moo;
use Business::GoCardless::Exception;

has endpoint => (
    is       => 'ro',
    default  => sub {
        my ( $self ) = @_;
        my ( $class ) = lc( ( split( ':',ref( $self ) ) )[-1] );
        return "/${class}s/%d";
    },
);

sub save_data {
    my ( $self,$data ) = @_;

    if ( $self->persisted ) {
        Business::GoCardless::Exception->throw({
            error => ref( $self ) . " cannot be updated"
        }) if ! $self->updatable;
    } else {
        Business::GoCardless::Exception->throw({
            error => ref( $self ) . " cannot be created"
        }) if ! $self->creatable;
    }

    my $method = $self->persisted ? 'put' : 'post';
    my $path   = sprintf( $self->endpoint,$self->id );
    my $res    = $self->client->send( "api_${method}",$path,$data );

}

1;

# vim: ts=4:sw=2:et
