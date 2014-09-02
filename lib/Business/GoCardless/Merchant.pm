package Business::GoCardless::Merchant;

use Moo;
extends 'Business::GoCardless::Resource';

use Business::GoCardless::Bill;
use Business::GoCardless::PreAuthorization;
use Business::GoCardless::Payout;

has [ qw/
    balance
    created_at
    description
    email
    eur_balance
    eur_pending_balance
    first_name
    gbp_balance
    gbp_pending_balance
    hide_variable_amount
    id
    last_name
    name
    next_payout_amount
    next_payout_date
    pending_balance
    sub_resource_uris
    uri
/ ] => (
    is => 'rw',
);

sub BUILD {
    my ( $self ) = @_;

    my $data = $self->client->api_get( sprintf( $self->endpoint,$self->id ) );

    foreach my $attr ( keys( %{ $data } ) ) {
        $self->$attr( $data->{$attr} );
    }

    return $self;
}

sub bills              { shift->_list( 'bills','Bill' ) }
sub pre_authorizations { shift->_list( 'pre_authorizations','PreAuthorization' )}
sub subscriptions      { shift->_list( 'subscriptions','Subscription' ) }
sub payouts            { shift->_list( 'payouts','Payout' ) }

sub _list {
    my ( $self,$endpoint,$class ) = @_;

    my $data = $self->client->api_get(
        sprintf( $self->endpoint,$self->id ) . "/$endpoint"
    );

    $class = "Business::GoCardless::$class";
    my @objects = map { $class->new( client => $self->client,%{ $_ } ) }
        @{ $data };

    return @objects;
}

1;

# vim: ts=4:sw=4:et
