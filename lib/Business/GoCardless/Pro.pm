package Business::GoCardless::Pro;

=head1 NAME

Business::GoCardless::Pro

=head1 DESCRIPTION


=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless';

has api_version => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub { 2 },
);

1;
