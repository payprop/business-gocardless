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

    $c->redirect_to( $r_uri // 'http://www.google.com' );
};

sub _bad_request {
    my ( $c,$text ) = @_;
    $c->render(
        text   => $text,
        status => 400
    );
}

app->start;

# vim: ts=4:sw=2:et
