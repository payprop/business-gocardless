#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use LWP::Simple;
use Business::GoCardless;
use Mojo::JSON qw/ decode_json /;

use FindBin qw/ $Bin /;
my $tmp_dir = "$Bin/end_to_end";

plan skip_all => "GOCARDLESS_ENDTOEND required"
    if ! $ENV{GOCARDLESS_ENDTOEND};

# this is an "end to end" test - it will call the gocardless API
# using the details defined in the ENV variables below. you need
# to run t/gocardless_callback_reader.pl allowing the callbacks
# from gocardless to succeed, which feeds the details back into
# this script (hence "end to end")
my ( $token,$url,$app_id,$app_secret,$mid ) = @ENV{qw/
    GOCARDLESS_TOKEN
    GOCARDLESS_TEST_URL
    GOCARDLESS_APP_ID
    GOCARDLESS_APP_SECRET
    GOCARDLESS_MERCHANT_ID
/};

# this makes Business::GoCardless::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{GOCARDLESS_DEV_TESTING} = 1;

my $GoCardless = Business::GoCardless->new(
    token           => $token,
    client_details  => {
        base_url    => $url,
        app_id      => $app_id,
        app_secret  => $app_secret,
        merchant_id => $mid,
    },
);

isa_ok( $GoCardless,'Business::GoCardless' );

=cut
my $new_url = $GoCardless->client->new_bill_url({
    amount       => 100,
    name         => 'Example payment',
    redirect_uri => "http://localhost:3000/merchants/$mid/confirm_resource",
});

# TODO: maybe automate this
diag "Visit and complete: $new_url";
my $confirm_resource_data = _get_confirm_resource_data( "$tmp_dir/bill.json" );
isa_ok(
    my $Bill = $GoCardless->client->confirm_resource( $confirm_resource_data ),
    'Business::GoCardless::Bill'
);

ok( $Bill->cancel,'cancel bill' );
ok( $Bill->cancelled,'bill cancelled' );

my $NewBill = $GoCardless->bill( $Bill->id );
is( $NewBill->id,$Bill->id,'getting bill with same id gives same bill' );
=cut

my $Paginator = $GoCardless->bills(
    per_page => 5,
);

note explain $Paginator->info;

while ( my @bills = $Paginator->next ) {
    note scalar( @bills );
    note explain [ map { $_->id } @bills ];
}

done_testing();

sub _get_confirm_resource_data {

    my ( $file ) = @_;

    while ( 1 ) {

        if ( -e $file ) {
            sleep( 1 );
            open( my $fh,'<',$file ) || die "Can't open $file for read: $!";
            do {
                local $/;
                my $content = <$fh>;
                close( $fh );
                unlink( $file ) || warn "Couldn't unlink $file: $!";
                return decode_json( $content )
            };
        }

        diag "Waiting for $file to appear...";
        sleep( 5 );
    }
}
