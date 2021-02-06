#!perl
# t/110-hopen-file-kit.t: test App::hopen::HopenFileKit;

{    # Tell HopenFileKit it's OK to load
    no warnings 'once';
    our $IsHopenFile;    # hard-coded HOPEN_FILE_FLAG
}

use rlib 'lib';
use HopenTest;

use App::hopen::HopenFileKit;
use App::hopen::MYhopen;
use App::hopen::Util;
use App::hopen::Util::Thunk;

sub subname () { my @x = caller(1); $x[3] }

sub test_dethunk {
    my $config = { y => [1337], n => ['oops'] };
    my $data   = {
        answer => 42,
        option => [
            65536, 128, 64,
            App::hopen::Util::Thunk->new(tgt => $config->{n}, name => "n")
        ],
        thunk => App::hopen::Util::Thunk->new(tgt => $config->{y}, name => "y")
    };

    diag subname
      . " before\n"
      . nicedump([ $config, $data ], [qw(Config Data)]);
    dethunk($data);
    diag subname . " after\n" . nicedump([ $config, $data ], [qw(Config Data)]);

    is_deeply(
        $data, {
            answer => 42,
            option => [ 65536, 128, 64, ['oops'] ],
            thunk  => [1337]
        },
        'dethunk replaced a thunk'
    );
} ## end sub test_dethunk

sub test_invalid_load {
    eval "package NONEXISTENT; use App::hopen::HopenFileKit";
    like(
        $@,
        qr/Not loaded as a hopen file/,
        'Rejects load from package without sentinel var'
    );
} ## end sub test_invalid_load

test_dethunk;
test_invalid_load;

done_testing();
