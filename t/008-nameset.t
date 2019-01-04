#!perl
# t/007-nameset.t: test Build::Hopen::Util::NameSet
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::Util::NameSet';
}

# NOTE: Even though `$s ~~ 'x'` is supported for now, we don't use it.
# This is to retain compatibility with the 5.27.7-style smartmatch
# if that ever comes back (http://blogs.perl.org/users/leon_timmermans/2017/12/smartmatch-in-5277.html).

my $s;

for(my $iter=0; $iter<2; ++$iter) {

    # Set up this iter's test object
    if($iter == 0) {
        $s = Build::Hopen::Util::NameSet->new();
        isa_ok($s, 'Build::Hopen::Util::NameSet');
        ok(!$s->contains('x'), "Empty nameset doesn't contain 'x'");
        ok(!('x' ~~ $s), "Empty nameset doesn't accept 'x'");
        $s->add('foo', 'bar', qr/bat/, [qr/qu+x/i, 'array', ['inner array']],
                {key=>'value'});

    } elsif($iter == 1) {
        $s = Build::Hopen::Util::NameSet->new(
            'foo', 'bar', qr/bat/, [qr/qu+x/i, 'array', ['inner array']],
            {key=>'value'});
        isa_ok($s, 'Build::Hopen::Util::NameSet');
    }

    # Test
    ok(!$s->contains('x'), "Nameset doesn't contain 'x'");
    ok(!('x' ~~ $s), "Nameset doesn't accept 'x'");
    ok($s->contains($_), "Nameset accepts literal $_")
        foreach (qw(foo bar array key), 'inner array');
    ok($_ ~~ $s, "Nameset accepts literal $_ ~~")
        foreach qw(foo bar array key), 'inner array';
    ok($s->contains($_), "Nameset accepts $_") foreach qw(bat qux QUX QuUuUx);
    ok($_ ~~ $s, "Nameset accepts $_ ~~") foreach qw(bat qux QUX QuUuUx);

    # Partial words shouldn't succeed
    ok(!($_ ~~ $s), "Nameset does not accept $_")
        foreach qw(foobar fooqux fooQUX other_inner_array foofoo batqux batarray);

}

done_testing();
