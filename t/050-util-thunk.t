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
my $h = { foo => $t, some_scalar => 1337 };
my $t2 = App::hopen::Util::Thunk->new(tgt => \($h->{some_scalar}), name => 'another_one');

my $optvalue = 'default';
my $conf = { scalar_option => $t2, optvalue => \$optvalue };
my $t3 = App::hopen::Util::Thunk->new(tgt => \($conf->{optvalue}), name => 'optvalue');
my $dumper = Data::Dumper->new([$conf, $answer, \$answer, $h, \$answer], ['config', $t->name, 'dref', 'hashref', 'directref']);
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
