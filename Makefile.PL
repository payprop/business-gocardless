#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Business::GoCardless',
    VERSION_FROM     => 'lib/Business/GoCardless.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM => {
        'Moo'           => 1.006,
        'Carp'          => 0, # Carp was first released with perl 5
        'OAuth::Simple' => 1.01,
        'Throwable'     => 0.200011,
    },
    BUILD_REQUIRES => {
        'Test::Most'      => 0.31,
        'Test::Deep'      => 0.112,
        'Test::Exception' => 0.32,
        'FindBin'         => 0, # FindBin was first released with perl 5.00307
        'Mojolicious'     => 5.28,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Business::GoCardless',
            bugtracker => 'https://github.com/leejo/business-gocardless/issues',
            repository => 'https://github.com/leejo/business-gocardless'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=2:et
