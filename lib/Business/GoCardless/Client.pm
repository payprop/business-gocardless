package Business::GoCardless::Client;

use Moo;
with 'Business::GoCardless::Utils';
use Business::GoCardless::Exception;
use Business::GoCardless::Bill;

use Carp qw/ confess /;
use POSIX qw/ strftime /;
use MIME::Base64 qw/ encode_base64 /;
use LWP::UserAgent;

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

has merchant_id => (
    is       => 'rw',
);

sub new_subscription_url {
    my ( $self,$params ) = @_;
    $self->new_limit_url( 'subscription',$params );
}

sub new_pre_authorization_url {
    my ( $self,$params ) = @_;
    $self->new_limit_url( 'pre_authorization',$params );
}

sub new_bill_url {
    my ( $self,$params ) = @_;
    $self->new_limit_url( 'bill',$params );
}

sub new_limit_url {
    my ( $self,$type,$limit_params ) = @_;

    $limit_params->{merchant_id} = $self->merchant_id;

    my $params = {
        nonce     => $self->generate_nonce,
        timestamp => strftime( "%Y-%m-%dT%H:%M:%SZ",gmtime ),
        client_id => $self->app_id,
        $type     => $limit_params,
        ( map {
            ( $limit_params->{$_} ? ( $_ => $limit_params->{$_} ) : () )
        } qw/ redirect_uri cancel_uri cancel_uri / )
    };

    $params->{signature} = $self->sign_params( $params,$self->app_secret );

    return sprintf(
        "%s/connect/%ss/new?%s",
        $self->base_url,
        $type,
        $self->normalize_params( $params )
    );
}

sub confirm_resource {
    my ( $self,$params ) = @_;

    if ( ! $self->signature_valid( $params,$self->app_secret ) ) {
        Business::GoCardless::Exception->throw({
            error => "Invalid signature for confirm_resource"
        });
    }

    my $data = {
        resource_id   => $params->{resource_id},
        resource_type => $params->{resource_type},
    };

    my $credentials = encode_base64( $self->app_id . ':' . $self->app_secret );
    $credentials    =~ s/\s//g;

    my $ua = LWP::UserAgent->new;
    $ua->agent( $self->_user_agent );

    my $req = HTTP::Request->new(
        POST => join( '/',$self->base_url . $self->api_path,'confirm' )
    );

    $req->header( 'Authorization' => "Basic $credentials" );
    $req->content_type( 'application/x-www-form-urlencoded' );
    $req->content( $self->normalize_params( $data ) );

#main::note main::explain $req;
    my $res = $ua->request( $req );

    if ( $res->is_success ) {
        
print $res->content;
        my $class = "Business::GoCardless::".ucfirst( $params->{resource_type} );
        return $class->new( id => $params->{resource_id} );
    }
    else {
print $res->status_line;
        Business::GoCardless::Exception->throw({
            error => $res->status_line
        });
    }
}

sub _user_agent {
    my ( $self ) = @_;

    return "business-gocardless/perl/v" . $Business::GoCardless::VERSION;
}

1;

# vim: ts=4:sw=4:et
