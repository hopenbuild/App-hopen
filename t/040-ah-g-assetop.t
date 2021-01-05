#!perl
# t/040-ah-g-assetop: tests of App::hopen::G::AssetOp
use rlib 'lib';
use HopenTest;
use Test::Fatal;

use App::hopen::G::AssetOp;

ok exception { App::hopen::G::AssetOp->new(asset=>$_) },
    "Rejects asset " . ($_ // 'undef')
    foreach (undef, 'hello', 42);

done_testing();
