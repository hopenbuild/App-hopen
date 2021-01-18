#!perl
# t/060-util-phasemanager.t - tests of App::hopen::Util::PhaseManager
use rlib 'lib';
use HopenTest 'App::hopen::Util::PhaseManager';
use Data::Dumper;
use Test::Fatal;

use App::hopen::Util;

sub test_new_first_last {
    like( exception { $DUT->new }, qr/Need phase/, 'missing phases' );
    like( exception { $DUT->new('0') }, qr/phase.+truthy/, '0 single phase' );
    like( exception { $DUT->new('') }, qr/phase.+truthy/, '"" single phase' );
    like( exception { $DUT->new(qw(0 x)) }, qr/phase.+truthy/, '0 single phase at front' );
    like( exception { $DUT->new(qw(x 0)) }, qr/phase.+truthy/, '0 single phase at end' );

    my $dut;

    $dut = $DUT->new(qw(a));
    isa_ok($dut, $DUT);
    is_deeply($dut, {0 => [qw(a)], a => ''}, 'single phase');
    is($dut->first, 'a', 'first: single phase');
    is($dut->last, 'a', 'last: single phase');

    $dut = $DUT->new(qw(a b));
    isa_ok($dut, $DUT);
    is_deeply($dut, {0 => [qw(a b)], a => 'b', b => ''}, 'two phases');
    is($dut->first, 'a', 'first: two phases');
    is($dut->last, 'b', 'last: two phases');

    $dut = $DUT->new(qw(a b c));
    isa_ok($dut, $DUT);
    is_deeply($dut, {0 => [qw(a b c)], a => 'b', b => 'c', c => ''}, 'three phases');
    is($dut->first, 'a', 'first: three phases');
    is($dut->last, 'c', 'last: three phases');

    $dut = $DUT->new(qw(Foo baR BAT));
    isa_ok($dut, $DUT);
    is_deeply($dut, {0 => [qw(foo bar bat)], foo => 'bar', bar => 'bat', bat => ''}, 'three phases, with fc');
    is($dut->first, 'foo', 'first: three phases, fc');
    is($dut->last, 'bat', 'last: three phases, fc');
}

sub test_check_enforce {
    my $dut = $DUT->new(qw(foo bar bat));
    ok(!$dut->check('nonexistent'), 'check: nonexistent');
    like( exception { $dut->enforce('nonexistent') }, qr/Unknown.+nonexistent/,
        'enforce nonexistent');

    is($dut->check($_), 'foo', "check: $_") foreach qw(foo FOO Foo fOo foO FOo FoO fOO);
    is($dut->enforce($_), 'foo', "enforce $_") foreach qw(foo FOO Foo fOo foO FOo FoO fOO);
    is($dut->check($_), $_, "check: $_") foreach qw(bar bat);
    is($dut->enforce($_), $_, "enforce $_") foreach qw(bar bat);
}

sub test_is {
    my $dut = $DUT->new(qw(foo bar bat));
    ok($dut->is($_, 'foo'), "is: $_") foreach qw(foo FOO Foo fOo foO FOo FoO fOO);
    ok($dut->is($_, uc $_), "is: $_") foreach qw(bar bat);
    ok(!$dut->is('nonexistent', 'foo'), 'nonexistent != foo');
    ok(!$dut->is('foo', 'nonexistent'), 'foo != nonexistent');
    ok(!$dut->is('oops', 'nonexistent'), 'oops != nonexistent');
}

sub test_next {
    my $dut = $DUT->new(qw(foo bar bat));
    like( exception { $dut->next('nonexistent') }, qr/Unknown phase/, 'next: unknown phase' );
    is($dut->next($_), 'bar', "next: $_") foreach qw(foo FOO Foo fOo foO FOo FoO fOO);
    is($dut->next('bar'), 'bat', 'next: bar');
    is($dut->next('bat'), '', 'next: bat');
}

sub test_is_last {
    my $dut = $DUT->new(qw(foo bar bat));
    like( exception { $dut->is_last('nonexistent') }, qr/Unknown phase/, 'is_last: unknown phase' );
    ok(!$dut->is_last($_), "is_last: $_") foreach qw(foo bar FOO BAR);
    ok($dut->is_last($_), "is_last: $_") foreach qw(bat BAT);
}

sub test_all {
    my $dut = $DUT->new(qw(foo bar bat));
    is_deeply([$dut->all], [qw(foo bar bat)], 'all');
    $dut = $DUT->new(qw(foo BAR bat));
    is_deeply([$dut->all], [qw(foo bar bat)], 'all with fc');
}

test_new_first_last;
test_check_enforce;
test_is;
test_next;
test_is_last;
test_all;

done_testing();