package Business::GoCardless::Resource;

use Moo;
use Business::GoCardless::Exception;
use Carp qw/ confess /;
use JSON ();

has endpoint => (
    is       => 'ro',
    default  => sub {
        my ( $self ) = @_;
        my ( $class ) = ( split( ':',ref( $self ) ) )[-1];

        confess( "You must subclass Business::GoCardless::Resource" )
            if $class eq 'Resource';

        $class =~ s/([a-z])([A-Z])/$1 . '_' . lc( $2 )/eg;
        $class = lc( $class );
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

sub find_with_client {
    my ( $self ) = @_;

    my $path = sprintf( $self->endpoint,$self->id );
    my $data = $self->client->api_get( $path );

    foreach my $attr ( keys( %{ $data } ) ) {
        $self->$attr( $data->{$attr} );
    }

    return $self;
}

sub _operation {
    my ( $self,$operation,$method,$params ) = @_;

    $method //= 'api_post',

    my $uri = $operation
        ? sprintf( $self->endpoint,$self->id ) . "/$operation"
        : sprintf( $self->endpoint,$self->id );

    my $data = $self->client->$method( $uri,$params );

    foreach my $attr ( keys( %{ $data } ) ) {
        $self->$attr( $data->{$attr} );
    }

    return $self;
}

sub to_hash {
    my ( $self ) = @_;

    my %hash = %{ $self };
    delete( $hash{client} );
    return %hash;
}

sub to_json {
    my ( $self ) = @_;
    return JSON->new->canonical->encode( { $self->to_hash } );
}

1;

# vim: ts=4:sw=4:et
