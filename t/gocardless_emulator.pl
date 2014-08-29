#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::JSON;

get '/connect/bills/new' => sub {
    my ( $c ) = @_;

    my $amount = $c->param( 'bill[amount]' )       // return _bad_request( $c,'bill[amount] is required' );
    my $mid    = $c->param( 'bill[merchant_id]' )  // return _bad_request( $c,'bill[merchant_id] is required' );
    my $name   = $c->param( 'bill[name]' );
    my $desc   = $c->param( 'bill[description]' );
    my $user   = $c->param( 'bill[user]' );
    my $sig    = $c->param( 'signature' )          // return _bad_request( $c,'signature is required' );
    my $nonce  = $c->param( 'nonce' );
    my $cid    = $c->param( 'client_id' )          // return _bad_request( $c,'client_id is required' );
    my $time   = $c->param( 'timestamp' )          // return _bad_request( $c,'timestamp is required' );
    my $r_uri  = $c->param( 'redirect_uri' );
    my $c_uri  = $c->param( 'cancel_uri' );
    my $state  = $c->param( 'state' );

    $c->redirect_to( $r_uri // '/success' );
};

get '/success' => sub {
    my ( $c ) = @_;
    $c->render(
        text   => 'Success',
        status => 200,
    );
};

get '/merchants/:mid/confirm_resource' => sub {
    my ( $c ) = @_;
    foreach ( qw/
        resource_uri
        resource_id
        resource_type
        signature
        state
    / ) {
        warn "$_ => " . $c->param( $_ )
            if defined $c->param( $_ );
    }

    my $mid   = $c->param( 'mid' );
    my $uri   = $c->param( 'resource_uri' );
    my $id    = $c->param( 'resource_id' );
    my $type  = $c->param( 'resource_type' );
    my $sig   = $c->param( 'signature' );
    my $state = $c->param( 'state' );

    if ( $state ) {
        $c->redirect_to( "https://sandbox.gocardless.com/merchants/$mid/confirm_resource?resource_uri=$uri&resource_id=$id&resource_type=$type&signature=$sig&state=$state" );
    } else {
        $c->redirect_to( "https://sandbox.gocardless.com/merchants/$mid/confirm_resource?resource_uri=$uri&resource_id=$id&resource_type=$type&signature=$sig" );
    }
};

sub _bad_request {
    my ( $c,$text ) = @_;
    $c->render(
        text   => $text,
        status => 400
    );
}

app->start;

# vim: ts=4:sw=4:et
