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
        ok(!$s->contains('x'), "Empty nameset rejects 'x'");
        ok(!('x' ~~ $s), "Empty nameset rejects 'x'");
        $s->add('foo', 'bar', qr/bat/, [qr/qu+x/i, 'array', ['inner array']],
                {key=>'value'}, 'русский', 'язык');

    } elsif($iter == 1) {
        $s = Build::Hopen::Util::NameSet->new(
            'foo', 'bar', qr/bat/, [qr/qu+x/i, 'array', ['inner array']],
            {key=>'value'}, 'русский', 'язык');
        isa_ok($s, 'Build::Hopen::Util::NameSet');
    }

    # Test
    ok(!$s->contains('x'), "Nameset rejects 'x'");
    ok(!('x' ~~ $s), "Nameset rejects 'x'");
    ok($s->contains($_), "Nameset accepts literal $_")
        foreach (qw(foo bar array key), 'inner array');
    ok($_ ~~ $s, "Nameset accepts literal $_ ~~")
        foreach qw(foo bar array key), 'inner array';
    ok($s->contains($_), "Nameset accepts $_") foreach qw(bat qux QUX QuUuUx);
    ok($_ ~~ $s, "Nameset accepts $_ ~~") foreach qw(bat qux QUX QuUuUx);

    # UTF-8 words
    ok $_ ~~ $s, "Nameset accepts UTF8 $_" foreach qw(русский язык);

    # Some kanji and hiragana
    ok !($_ ~~ $s), "Nameset rejects UTF8 $_" foreach qw(日本語 ひらがな);

    # Partial words shouldn't succeed
    ok(!($_ ~~ $s), "Nameset rejects $_")
        foreach qw(foobar fooqux fooQUX other_inner_array foofoo batqux batarray);

}

done_testing();
# vi: set fenc=utf8:
