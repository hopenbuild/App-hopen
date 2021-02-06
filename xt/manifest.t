#!perl
use 5.014;
use strict;
use warnings;
use warnings;
use Test::More;
use ExtUtils::Manifest;

unless($ENV{RELEASE_TESTING}) {
    plan(skip_all => "Author tests not required for installation");
}

# Thanks to mohawk2, <https://github.com/reneeb/Test-CheckManifest/issues/20#issue-413124421>
is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';

done_testing();
