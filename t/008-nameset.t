#!perl
# t/007-nameset.t: test Build::Hopen::Util::NameSet
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::Util::NameSet';
}

my $s = Build::Hopen::Util::NameSet->new();
isa_ok($s, 'Build::Hopen::Util::NameSet');
ok(!$s->contains('x'), "Empty nameset doesn't contain 'x'");
ok(!($s ~~ 'x'), "Empty nameset doesn't contain 'x' (o~~s)");
ok(!('x' ~~ $s), "Empty nameset doesn't contain 'x' (s~~o)");
$s->add('foo', 'bar', qr/bat/, [qr/qu+x/i, 'array', ['inner array']],
        {key=>'value'});

ok(!$s->contains('x'), "Nameset still doesn't contain 'x'");
ok($s->contains($_), "Nameset accepts literal $_")
    foreach ('foo', 'bar', 'array', 'inner array', 'key');
ok($_ ~~ $s, "Nameset accepts literal $_ ~~")
    foreach ('foo', 'bar', 'array', 'inner array', 'key');
ok($s->contains($_), "Nameset accepts $_")
    foreach ('bat', 'qux', 'QUX', 'QuUuUx');
ok($_ ~~ $s, "Nameset accepts $_ ~~")
    foreach ('bat', 'qux', 'QUX', 'QuUuUx');

$s = Build::Hopen::Util::NameSet->new(
    'foo', 'bar', qr/bat/, [qr/qu+x/i, 'array', ['inner array']],
    {key=>'value'});
isa_ok($s, 'Build::Hopen::Util::NameSet');

ok(!$s->contains('x'), "Nameset doesn't contain 'x'");
ok(!($s ~~ 'x'), "Nameset doesn't contain 'x' (o~~s)");
ok(!('x' ~~ $s), "Nameset doesn't contain 'x' (s~~o)");
ok($s->contains($_), "Nameset accepts literal $_")
    foreach ('foo', 'bar', 'array', 'inner array', 'key');
ok($_ ~~ $s, "Nameset accepts literal $_ ~~")
    foreach ('foo', 'bar', 'array', 'inner array', 'key');
ok($s->contains($_), "Nameset accepts $_")
    foreach ('bat', 'qux', 'QUX', 'QuUuUx');
ok($_ ~~ $s, "Nameset accepts $_ ~~")
    foreach ('bat', 'qux', 'QUX', 'QuUuUx');

done_testing();
