#!perl
# t/120-myhopen.t: test App::hopen::MYhopen

use rlib 'lib';
use HopenTest;

use App::hopen::MYhopen;
use App::hopen::Util;
use App::hopen::Util::Thunk;

sub subname() { my @x = caller(1); $x[3] }

sub test_extract_thunks {
    my $data = { answer => 42, option => [ 65536, 128, 64,
        App::hopen::Util::Thunk->new(tgt=>['nope'], name=>"n")],
        thunk => App::hopen::Util::Thunk->new(tgt=>['yep'], name=>"y"),
        thunk2 => App::hopen::Util::Thunk->new(tgt=>['another one'], name=>"y"),
    };
    my $config = extract_thunks($data);
    is($data->{option}->[3]->name, 'n', 'unique name unchanged');
    is($data->{thunk}->name, 'y', 'first non-unique name unchanged');
    is($data->{thunk2}->name, 'y1', 'second non-unique name changed');
    is_deeply($config, {
        n => ['nope'],
        y => ['yep'],
        y1 => ['another one'],
    }, 'extract_thunks');
    ref_equal_ok($config->{n}, $data->{option}->[3]->tgt, 'unique ref');
    ref_equal_ok($config->{y}, $data->{thunk}->tgt, 'first non-unique ref');
    ref_equal_ok($config->{y1}, $data->{thunk2}->tgt, 'second non-unique ref');
}

test_extract_thunks;

done_testing();
