#!perl
# 030-util-basedpath.t: test App::hopen::Util::BasedPath
use rlib 'lib';
use HopenTest 'App::hopen::Util::BasedPath';
use Path::Class;

my $e2 = DUT->new(path=>dir(), base=>dir());
isa_ok($e2, $DUT);

$e2 = based_path(path=>dir(), base=>dir());
isa_ok($e2, $DUT);

eval { $e2 = DUT->new(path=>dir(), base=>""); };
ok($@, 'Constructor rejects base=>""');

$e2 = based_path(path=>dir(), base=>dir(''));
isa_ok($e2, $DUT);
ok($e2, 'Constructor accepts base=>dir("")');

# Some example test cases.  TODO convert these to workable cross-platform tests.
#$ perl -Ilib -MPath::Class -MApp::hopen::Util::BasedPath -E 'my $p = based_path(path=>file("foo.txt"), base=>dir("")); say $p->orig; say $p->path_on(dir("blah"))'
#/foo.txt
#blah/foo.txt
#$ perl -Ilib -MPath::Class -MApp::hopen::Util::BasedPath -E 'my $p = based_path(path=>file("foo.txt"), base=>dir("")); say $p->orig; say $p->path_on(dir("", "blah"))'
#/foo.txt
#/blah/foo.txt
#$ perl -Ilib -MPath::Class -MApp::hopen::Util::BasedPath -E 'my $p = based_path(path=>dir("blag")->file("foo.txt"), base=>dir("")); say $p->orig; say $p->path_on(dir("", "blah"))'
#/blag/foo.txt
#/blah/blag/foo.txt


done_testing();
