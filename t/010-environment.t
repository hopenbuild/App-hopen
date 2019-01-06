#!perl
# t/007-nameset.t: test Build::Hopen::Util::NameSet
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::Environment';
}

my $s = Build::Hopen::Environment->new();
isa_ok($s, 'Build::Hopen::Environment');

$s->{foo} = 42;
cmp_ok($s->find('foo'), '==', 42, 'Retrieving from hash works');

foreach my $varname (qw(SHELL COMSPEC PATH)) {
    is($s->find($varname), $ENV{$varname}, "Finds env var $varname")
        if exists $ENV{$varname};
}

done_testing();
# vi: set fenc=utf8:
