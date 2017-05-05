package Business::GoCardless::Basic;

=head1 NAME

Business::GoCardless::Basic

=head1 DESCRIPTION

This class is just an extension of Business::GoCardless

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless';

has api_version => (
    is       => 'ro',
    required => 0,
    default  => sub { 1 },
);

1;
