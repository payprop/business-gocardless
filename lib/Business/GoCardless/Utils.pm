package Business::GoCardless::Utils;

use Moo::Role;

use MIME::Base64 qw/ encode_base64 /;
use Digest::SHA qw/ hmac_sha256_hex /;

sub sign_params {
    my ( $self,$params,$app_secret ) = @_;

    return hmac_sha256_hex(
        $self->normalize_params( $params ),
        $app_secret
    );
}

sub signature_valid {
    my ( $self,$params,$app_secret ) = @_;

    # for testing, use live at your own risk
    return 1 if $ENV{GOCARDLESS_SKIP_SIG_CHECK};

    # delete local is 5.12+ only so need to copy hash here
    my $params_copy = { %{ $params } };
    my $sig = delete( $params_copy->{signature} );
    return $sig eq $self->sign_params( $params_copy,$app_secret );
}

sub generate_nonce {
    my ( $self ) = @_;

    chomp( my $nonce = encode_base64( time . '|' . rand(256) ) );
    return $nonce;
}

sub flatten_params {
    my ( $self,$params ) = @_;

    return [
        map { _flatten_param( $_,$params->{$_} ) }
        sort keys( %{ $params } )
    ];
}

sub normalize_params {
    my ( $self,$params ) = @_;

    return join( '&',
        map { $_->[0] . '=' . $_->[1]  }
        map { [ _rfc5849_encode( $_->[0] ),_rfc5849_encode( $_->[1] ) ] }
        sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] }
        @{ ref( $params ) eq 'HASH'
            ? $self->flatten_params( $params )
            : $params
        }
    );
}

sub _flatten_param { 
    my( $key,$value ) = @_;

    my @r;

    if ( ref( $value ) eq 'HASH' ) {
        foreach my $sub_key ( sort keys( %{ $value } ) ) {
            push( @r,_flatten_param( "$key\[$sub_key\]",$value->{$sub_key} ) );
        } 
    } elsif ( ref( $value ) eq 'ARRAY' ) {
        foreach my $sub_key ( @{ $value } ) {
            push( @r,_flatten_param( "$key\[\]",$sub_key ) );
        } 
    } else {
        push( @r,[ $key,$value ] );
    }

    return @r;
}

sub _rfc5849_encode {
    my ( $str ) = @_;

    $str =~ s#([^-.~_a-z0-9])#sprintf('%%%02X', ord($1))#gei;
    return $str;
}

1;

# vim: ts=4:sw=4:et
