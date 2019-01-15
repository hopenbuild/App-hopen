#!perl
# t/200-probe-basic.t - basic tests of Build::Hopen::Phase::Probe
use rlib 'lib';
use HopenTest;
use Test::Deep;
use Path::Class;

BEGIN {
    use_ok 'Build::Hopen::Phase::Probe';
}

sub cf { File::Spec->catfile(@_) }

my $dir = file($0)->parent->subdir('dir200')->subdir('inner');
diag "Looking in $dir";
my @candidates = find_hopen_files $dir;
is_deeply(\@candidates, [$dir->file('.hopen'), $dir->file('z.hopen')], 'finds candidates');

done_testing();
