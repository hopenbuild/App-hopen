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
use App::hopen::Util::Thunk;

{
    my $config = { y => [ 1337 ] };
    my $data = { answer => 42, option => [ 65536, 128, 64 ],
        thunk => App::hopen::Util::Thunk->new(tgt=>\($config->{y}), name=>"y")};
    dethunk($config, $data);
    is_deeply($data, { answer => 42, option => [ 65536 ],
        thunk => [ 1337 ] }, 'dethunk replaced a thunk');
}

done_testing();
