#!perl
# 900-eg-001.t: Test using eg/001.
use rlib 'lib';
use HopenTest;

use Capture::Tiny 'capture';
use Path::Class;
use Test::Directory;

use App::hopen;

sub test_with {     # Takes a generator
    my $gen = shift or croak 'Need a generator';
    diag "Testing with -g $gen";

    # Set up the dir and paths
    my $dest = Test::Directory->new;
    my $src = dir(qw(eg 001-single-file-hello));   # assume running in /, not /t

    # Check phase
    my ($stdout, $stderr, $exitcode) = capture {
        App::hopen::Main([
            '--fresh',
            -g => $gen,
            '--from', $src,
            '--to', $dest->path('.'),
        ]);
    };

    like $stdout, qr/\bCheck\b/, 'Ran "Check" phase';
    is $stderr, '', 'No error output' if $gen eq 'Make';
    cmp_ok $exitcode, '==', 0, 'Run succeeded';
    $dest->has('MY.hopen.pl');

    # Gen phase
    ($stdout, $stderr, $exitcode) = capture {
        App::hopen::Main([
            -g => $gen,
            '--from', $src,
            '--to', $dest->path('.'),
        ]);
    };

    like $stdout, qr/\bGen\b/, 'Ran "Gen" phase';
    is $stderr, '', 'No error output' if $gen eq 'Make';
    cmp_ok $exitcode, '==', 0, 'Run succeeded';
    $dest->has('MY.hopen.pl');
    $dest->has($gen eq 'Make' ? 'Makefile' : 'build.ninja');
    $dest->hasnt($gen eq 'Make' ?  'build.ninja' : 'Makefile');

} #test_with

test_with 'Make';
test_with 'Ninja';

done_testing();
