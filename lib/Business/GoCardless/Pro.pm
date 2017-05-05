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

has api_version => (
    is       => 'ro',
    required => 0,
    default  => sub { 2 },
);

# BACK COMPATIBILITY wrapper around _new_redirect_flow_url, will
# translate Basic API new_bill_url params to those required for
# the /redirect_flows endpoint
sub new_bill_url {
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
		}

	} else {

	}
}

sub payment {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Payment','payments' );
}

sub payments {
	my ( $self,%filters ) = @_;
	return $self->_list( 'payments',\%filters );
}

sub _list {
    my ( $self,$endpoint,$filters ) = @_;

    my $class = {
        payments => 'Payment',
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

1;
