package Business::GoCardless::Pro;

=head1 NAME

Business::GoCardless::Pro

=head1 DESCRIPTION


=cut

use strict;
use warnings;

use Carp qw/ confess /;
use Moo;
extends 'Business::GoCardless';

use Business::GoCardless::Payment;
use Business::GoCardless::RedirectFlow;
use Business::GoCardless::Subscription;
use Business::GoCardless::Customer;
use Business::GoCardless::Webhook::V2;

use Business::GoCardless::Exception

has api_version => (
    is       => 'ro',
    required => 0,
    default  => sub { 2 },
);

sub payment {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Payment','payments' );
}

sub payments {
	my ( $self,%filters ) = @_;
	return $self->_list( 'payments',\%filters );
}

sub subscription {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Subscription','subscriptions' );
}

sub subscriptions {
    my ( $self,%filters ) = @_;
	return $self->_list( 'subscriptions',\%filters );
}

sub pre_authorization {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'RedirectFlow','redirect_flows' );
};

sub pre_authorizations {
	Business::GoCardless::Exception->throw({
		message => "->pre_authorizations is no longer meaningful in the Pro API",
	});
};

sub customer {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Customer','customer' );
}

sub customers {
	my ( $self,%filters ) = @_;
	return $self->_list( 'customers',\%filters );
}

sub webhook {
	my ( $self,$data,$signature ) = @_;

    return Business::GoCardless::Webhook::V2->new(
        client     => $self->client,
        json       => $data,
		# load ordering handled by setting _signature rather than signature
		# signature will be set in the json trigger
		_signature => $signature,
    );
}

sub _list {
    my ( $self,$endpoint,$filters ) = @_;

    my $class = {
        payments       => 'Payment',
		redirect_flows => 'RedirectFlow',
		customers      => 'Customer',
		subscriptions  => 'Subscription',
    }->{ $endpoint };

    $filters //= {};

    my $uri = "/$endpoint";

    if ( keys( %{ $filters } ) ) {
        $uri .= '?' . $self->client->normalize_params( $filters );
    }

    my ( $data,$links,$info ) = $self->client->api_get( $uri );

    $class = "Business::GoCardless::$class";
    my @objects = map { $class->new( client => $self->client,%{ $_ } ) }
        @{ $data->{$endpoint} };

    return wantarray ? ( @objects ) : Business::GoCardless::Paginator->new(
        class   => $class,
        client  => $self->client,
        links   => $links,
        info    => $info ? JSON->new->decode( $info ) : {},
        objects => \@objects,
    );
}

################################################################
#
# BACK COMPATIBILITY SECTION FOLLOWS
# the Pro version of the API is built on "redirect flows" when
# using their hosted pages, so we can make it back compatible
#
################################################################

sub new_bill_url {
	my ( $self,%params ) = @_;
	return $self->_redirect_flow_from_legacy_params( %params );
}

sub new_pre_authorization_url {
	my ( $self,%params ) = @_;
	return $self->_redirect_flow_from_legacy_params( %params );
}

sub new_subscription_url {
	my ( $self,%params ) = @_;
	return $self->_redirect_flow_from_legacy_params( %params );
}

sub _redirect_flow_from_legacy_params {
    my ( $self,%params ) = @_;

	for ( qw/ session_token success_redirect_url / ) {
		$params{$_} // confess( "$_ is required for new_bill_url (v2)" );
	}

	# we can't just pass through %params as GoCardless will throw an error
	# if it receives any unknown parameters
    return $self->client->_new_redirect_flow_url({
		scheme               => $params{scheme},
		session_token        => $params{session_token},
		success_redirect_url => $params{success_redirect_url},
		description          => $params{description} // $params{name},
		prefilled_customer   => {
			address_line1           => $params{user}{billing_address1}        // '',
			address_line2           => $params{user}{billing_address2}        // '',
			address_line3           => $params{user}{billing_address3}        // '',
			city                    => $params{user}{city}                    // '',
			company_name            => $params{user}{company_name}            // '',
			country_code            => $params{user}{country_code}            // '',
			email                   => $params{user}{email}                   // '',
			family_name             => $params{user}{last_name}               // '',
			given_name              => $params{user}{given_name}              // '',
			language                => $params{user}{language}                // '',
			postal_code             => $params{user}{billing_postcode}        // '',
			region                  => $params{user}{region}                  // '',
			swedish_identity_number => $params{user}{swedish_identity_number} // '',
		},
		(
			$params{links}{creditor}
				? ( links => { creditor => $params{links}{creditor} } )
				: ()
		),
	});
}


# BACK COMPATIBILITY method, in which we (try to) return the correct object for
# the required type as this is how the v1 API works
sub confirm_resource {
    my ( $self,%params ) = @_;

	for ( qw/ redirect_flow_id type amount currency / ) {
		$params{$_} // confess( "$_ is required for confirm_resource (v2)" );
	}

	my $r_flow_id = $params{redirect_flow_id};
	my $type      = $params{type};
	my $amount    = $params{amount};
	my $currency  = $params{currency};
	my $int_unit  = $params{interval_unit};
	my $interval  = $params{interval};
	my $start_at  = $params{start_at};

    if ( my $RedirectFlow = $self->client->_confirm_redirect_flow( $r_flow_id ) ) {

		# now we have a confirmed redirect flow object we can create the
		# payment, subscription, whatever
		if ( $type =~ /bill|payment/i ) {

			# Bill -> Payment
			my $post_data = {
				payments => {
					amount   => $amount,
					currency => $currency,
					links    => {
						mandate => $RedirectFlow->links->{mandate},
					},
				},
			};

			my $data = $self->client->api_post( "/payments",$post_data );

			return Business::GoCardless::Payment->new(
				client => $self->client,
				%{ $data->{payments} },
			);

		} elsif ( $type =~ /pre_auth/i ) {

			# a pre authorization is, effectively, a redirect flow
			return $RedirectFlow;

		} elsif ( $type =~ /subscription/i ) {

			my $post_data = {
				subscriptions => {
					amount        => $amount,
					currency      => $currency,
					interval_unit => $int_unit,
					interval      => $interval,
					start_date    => $start_at,
					links => {
						mandate => $RedirectFlow->links->{mandate},
					},
				},
			};

			my $data = $self->client->api_post( "/subscriptions",$post_data );

			return Business::GoCardless::Subscription->new(
				client => $self->client,
				%{ $data->{subscriptions} },
			);
		}

		# don't know what to do, complain
		Business::GoCardless::Exception->throw({
			message => "Unkown type ($type) in ->confirm_resource",
		});
	}

	Business::GoCardless::Exception->throw({
		message => "Failed to get RedirectFlow for $r_flow_id",
	});
}

sub users { shift->customers( @_ ); }

1;
