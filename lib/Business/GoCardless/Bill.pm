package Business::GoCardless::Bill;

use Moo;
use Business::GoCardless::Exception;

extends 'Business::GoCardless::Resource';

sub creatable { 1 }
sub updatable { 0 }
sub persisted { 0 }

has [ qw/
    id amount gocardless_fees partner_fees amount_minus_fees
    currency description name status
    can_be_retried can_be_cancelled is_setup_fee
    source_id source_type
    merchant_id user_id payout_id
    created_at paid_at charge_customer_at
/ ] => (
    is => 'ro',
);

sub source {
    my ( $self,$obj ) = @_;

    if ( $obj ) {

        my $valid_sources = {
            'Subscription'     => 1,
            'PreAuthorization' => 1,
        };

        $valid_sources->{ ref( $obj ) }
            or Business::GoCardless::Exception->throw({
                message => "source object must be one of "
                . join( ", ", sort keys( %{ $valid_sources } ) )
            });

        $self->source_id( $obj->id );
        $self->source_type( ref( $obj ) );
    } else {
        return $self->source_type;
    }
}

sub retry  { shift->_operation( 'retry' ); }
sub cancel { shift->_operation( 'cancel' ); }
sub refund { shift->_operation( 'refund' ); }

sub save {
    my ( $self ) = @_;

    my $bill_params = {
        map { $_ => $self->$_ }
        grep { defined( $self->$_ ) }
        qw/ amount name description charge_customer_at /
    };

    $bill_params->{pre_authorization_id} = $self->source_id;

    $self->save_data({ bill => $bill_params });

    return $self;
}

sub pending   { return shift->status eq 'pending' }
sub paid      { return shift->status eq 'paid' }
sub failed    { return shift->status eq 'failed' }
sub withdrawn { return shift->status eq 'withdrawn' }
sub refunded  { return shift->status eq 'refunded' }

1;

# vim: ts=4:sw=4:et
