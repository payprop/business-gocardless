package Business::GoCardless::PreAuthorization;

use Moo;
extends 'Business::GoCardless::Resource';

use Business::GoCardless::Exception;
use Business::GoCardless::Bill;

has [ qw/
    created_at
    currency
    description
    expires_at
    id
    interval_length
    interval_unit
    max_amount
    merchant_id
    name
    next_interval_start
    remaining_amount
    setup_fee
    status
    sub_resource_uris
    uri
    user_id
/ ] => (
    is => 'rw',
);

sub bill {
    my ( $self,%params ) = @_;

    my $data = $self->client->api_post(
        "/bills",
        {
            bill => {
                pre_authorization_id => $self->id,
                %params,
            }
        }
    );

    return Business::GoCardless::Bill->new(
        client => $self->client,
        %{ $data }
    );
}

sub cancel { shift->_operation( 'cancel','api_put' ); }

sub inactive  { return shift->status eq 'inactive' }
sub active    { return shift->status eq 'active' }
sub cancelled { return shift->status eq 'cancelled' }
sub expired   { return shift->status eq 'expired' }

1;

# vim: ts=4:sw=4:et
