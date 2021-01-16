#!perl
# t/050-util-thunk.t - tests of App::hopen::Util::Thunk
use rlib 'lib';
use HopenTest;
use Data::Dumper;
use Test::Fatal;

use App::hopen::Util;
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
    diag nicedump([$conf, $data], ['Config', 'Data']);
}

like( exception { App::hopen::Util::Thunk->new }, qr/tgt.+required/, 'tgt required' );
like( exception { App::hopen::Util::Thunk->new(tgt => 42) }, qr/tgt.+reference/, 'tgt ref' );
like( exception { App::hopen::Util::Thunk->new(tgt => []) }, qr/name.+required/, 'name required' );
like( exception { App::hopen::Util::Thunk->new(tgt => [], name => \'') }, qr/name.+reference/, 'name ref' );

done_testing();
