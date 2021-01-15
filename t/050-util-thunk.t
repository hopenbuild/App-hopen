#!perl
# t/050-util-thunk.t - tests of App::hopen::Util::Thunk
use rlib 'lib';
use HopenTest;
use Data::Dumper;

use App::hopen::Util::Thunk;

our $answer = 42;
my $t = App::hopen::Util::Thunk->new(tgt => \$answer, name => 'perl_ident');
is(${$t->tgt}, 42);
is($t->name, 'perl_ident');

{
    my $conf = { quux => [ 'some value' ] };
    my $data = { x => 42, y => 1337,
        option => App::hopen::Util::Thunk->new(tgt => \$conf->{quux}, name => 'another_one'),
    };
    dumpit([$conf, $data], ['Config', 'Data']);
}

done_testing();

sub dumpit {
    my $dumper = Data::Dumper->new(@_);
    $dumper->Indent(1);         # fixed indent size
    $dumper->Quotekeys(0);
    $dumper->Purity(1);
    $dumper->Maxrecurse(0);     # no limit
    $dumper->Sortkeys(true);    # For consistency between runs
    $dumper->Terse(false);

    diag $dumper->Dump;
    diag '';
}
