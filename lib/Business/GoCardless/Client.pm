package Business::GoCardless::Client;

use Moo;
use Carp qw/ confess /;
use OAuth::Simple;

has token => (
    is       => 'ro',
    required => 1,
);

has base_url => (
    is       => 'ro',
    required => 0,
    default  => sub { 'https://gocardless.com' },
);

has api_path => (
    is       => 'ro',
    required => 0,
    default  => sub { '/api/v1' },
);

has app_id => (
    is       => 'ro',
    default  => sub {
        $ENV{'GOCARDLESS_APP_ID'}
            or confess( "Missing required argument: app_id" );
    }
);

has app_secret => (
    is       => 'ro',
    default  => sub {
        $ENV{'GOCARDLESS_APP_SECRET'}
            or confess( "Missing required argument: app_secret" );
    }
);

has oauth_client => (
    is       => 'ro',
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;

        return OAuth::Simple->new(
            app_id     => $self->app_id,
            secret     => $self->app_secret,
#           postback   => 'POSTBACK URL',
        );
    },
);

sub authorize_url {
    my ( $self ) = @_;

    my $url = $self->oauth_client->authorize({
        url           => $self->base_url . '/oauth/authorize',
        client_id     => $self->app_id,
        response_type => 'code',
        scope         => 'manage_merchant',
    });
    # Your web app redirect method.
    #$self->redirect($url);
}

sub new_bill_url {
    my ( $self,$params ) = @_;
    $self->new_limit_url( 'bill',$params );
}

sub new_limit_url {
    my ( $self,$type,$limit_params ) = @_;
}

1;

# vim: ts=4:sw=2:et
