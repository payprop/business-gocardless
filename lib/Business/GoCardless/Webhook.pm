package Business::GoCardless::Webhook;

=head1 NAME

Business::GoCardless::Webhook

=head1 DESCRIPTION

A class for a gocardless webhooks, extends L<Business::GoCardless::Resource>.
For more details see the gocardless API documentation specific to webhooks:
https://developer.gocardless.com/#webhook-overview

=cut

use Moo;
extends 'Business::GoCardless::Resource';
with 'Business::GoCardless::Utils';

use JSON ();
use Business::GoCardless::Exception;

=head1 ATTRIBUTES

    resource_type
    action

=cut

has [ qw/
    resource_type
    action
    _payload
/ ] => (
    is => 'rw',
	clearer => 1,
);

=head1 Operations on a webhook

=head2 json

Allows you to set the json data sent to you in the webhook:

	$Webhook->json( $json_data )

Will throw a L<Business::GoCardless::Exception> exception if the json fails to
parse or if the signature does not match the payload data.

=cut

has json => (
	is       => 'rw',
    required => 1,
    trigger  => sub {
        my ( $self,$json ) = @_;

        # defensive decoding
		my $params;
		eval { $params = JSON->new->decode( $json ) };
		$@ && do {
			$self->_clear_payload;
			$self->clear_resource_type;
			$self->clear_action;

			Business::GoCardless::Exception->throw({
				message  => "Failed to parse json: $@",
			});
		};

		$self->resource_type( $params->{payload}{resource_type} );
		$self->action( $params->{payload}{action} );
		$self->_payload( $params->{payload} );

		if ( ! $self->signature_valid(
			$params->{payload},$self->client->app_secret )
		) {
			$self->_clear_payload;
			$self->clear_resource_type;
			$self->clear_action;

			Business::GoCardless::Exception->throw({
				message  => "Invalid signature for webhook",
			});
		}

        return $json;
    }
);

=head2 resources

Returns an array of resource objects (Bill, Subscription, etc) that are present
in webhook allowing you to do things with them or update your own data:

	if ( $Webhook->resource_type eq 'bill' ) {
		foreach my $Bill ( $Webhook->resources ) {
			...
		}
	} elsif ( $Webhook->resource_type eq 'subscription' ) {
		...

=cut

sub resources {
	my ( $self ) = @_;

	my @resources;

	return if ! $self->resource_type;

	my $key = {
		bill              => 'bills',
		pre_authorization => 'pre_authorizations',
		subscription      => 'subscriptions',
	}->{ $self->resource_type };

	my $class_suffix = ucfirst( $self->resource_type );
	$class_suffix    =~ s/_([A-z])/uc($1)/ge;
	my $class = "Business::GoCardless::$class_suffix";

	foreach my $hash ( @{ $self->_payload->{ $key } } ) {

        my $obj   = $class->new(
            client => $self->client,
            %{ $hash },
        );

		push( @resources,$obj );
	}

	return @resources;
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
