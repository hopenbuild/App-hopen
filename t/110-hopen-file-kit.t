#!perl
# t/110-hopen-file-kit.t: test App::hopen::HopenFileKit;

{ # Tell HopenFileKit it's OK to load
    no warnings 'once';
    our $IsHopenFile;   # hard-coded HOPEN_FILE_FLAG
}

use rlib 'lib';
use HopenTest;
use Test::Deep;
#use Path::Class;

use App::hopen::HopenFileKit;
use App::hopen::Util;
use App::hopen::Util::Thunk;

{
    my $config = { y => [ 1337 ], n => [ 'oops' ] };
    my $data = { answer => 42, option => [ 65536, 128, 64,
        App::hopen::Util::Thunk->new(tgt=>$config->{n}, name=>"n")],
        thunk => App::hopen::Util::Thunk->new(tgt=>$config->{y}, name=>"y")};

    diag "Before\n" . nicedump([$config, $data], [qw(Config Data)]);
    dethunk($data);
    diag "After\n" . nicedump([$config, $data], [qw(Config Data)]);

    is_deeply($data, { answer => 42, option => [ 65536, 128, 64, ['oops'] ],
        thunk => [ 1337 ] }, 'dethunk replaced a thunk');
}

done_testing();
