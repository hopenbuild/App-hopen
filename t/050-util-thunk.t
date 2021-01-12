#!perl
# t/050-util-thunk.t - tests of App::hopen::Util::Thunk
use rlib 'lib';
use HopenTest;
use Data::Dumper;
use Test::Deep;

BEGIN { $Data::Dumper::Indent = 1; }

use App::hopen::Util::Thunk;

my $answer = 42;
my $t = App::hopen::Util::Thunk->new(tgt => \$answer, name => 'perl_ident');
is($t->get, 42);
is($t->name, 'perl_ident');

# TODO RESUME HERE convince Dumper to output the refs with the name of the
# variable rather than with the direct value.
my $h = { foo => $t };
my $dumper = Data::Dumper->new([$answer, $h, \$answer], [$t->name, 'hashref', 'directref']);
$dumper->Indent(1);         # fixed indent size
$dumper->Quotekeys(0);
$dumper->Purity(1);
$dumper->Maxrecurse(0);     # no limit
$dumper->Sortkeys(true);    # For consistency between runs
$dumper->Sparseseen(true);  # We don't use Seen()
$dumper->Terse(false);

diag $dumper->Dump;

done_testing();
