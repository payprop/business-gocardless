package Business::GoCardless::Exception;

use Moo;
use JSON;

with 'Throwable';

# plain string or JSON
has message => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        my ( $message ) = @_;

        if ( $message =~ /^[{\[]/ ) {
            # defensive decoding
            eval { $message = JSON->new->decode( $message ) };
            $@ && do { return "Failed to parse JSON response ($message): $@"; };

            if ( ref( $message ) eq 'HASH' ) {
                my $error = delete( $message->{error} ) // "Unknown error";
                return ref( $error ) ? join( ', ',@{ $error } ) : $error;
            } else {
                return join( ', ',@{ $message } );
            }
        } else {
            return $message;
        }
    },
);

# compatibility with ruby lib
sub description { shift->message }

# generally the HTTP status code
has code => (
    is       => 'ro',
    required => 0,
);

# generally the HTTP status code + message
has response => (
    is       => 'ro',
    required => 0,
);

1;

# vim: ts=4:sw=4:et
