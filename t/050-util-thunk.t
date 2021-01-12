#!perl
# t/050-util-thunk.t - tests of App::hopen::Util::Thunk
use rlib 'lib';
use HopenTest;
use Data::Dumper;
use Test::Deep;

BEGIN { $Data::Dumper::Indent = 1; }

use App::hopen::Util::Thunk;

our $answer = 42;
my $t = App::hopen::Util::Thunk->new(tgt => \$answer, name => 'perl_ident');
is($t->get, 42);
is($t->name, 'perl_ident');

# TODO RESUME HERE convince Dumper to output the refs with the name of the
# variable rather than with the direct value.
my $h = { foo => $t };
my $dumper = Data::Dumper->new([$answer, \$answer, $h, \$answer], [$t->name, 'dref', 'hashref', 'directref']);
$dumper->Indent(1);         # fixed indent size
$dumper->Quotekeys(0);
$dumper->Purity(1);
$dumper->Maxrecurse(0);     # no limit
$dumper->Sortkeys(true);    # For consistency between runs
$dumper->Sparseseen(true);  # We don't use Seen()
$dumper->Terse(false);
# Maybe use a custom bless() analog, and have Thunk take a string
# for tgt?  Then have custombless() replace the string with a reference?

diag $dumper->Dump;

done_testing();
