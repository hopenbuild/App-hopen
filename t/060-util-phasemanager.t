#!perl
# t/060-util-phasemanager.t - tests of App::hopen::Util::PhaseManager
use rlib 'lib';
use HopenTest 'App::hopen::Util::PhaseManager';
use Data::Dumper;
use Test::Fatal;

use App::hopen::Util;

context 'New, first, last: ' => sub {
    it 'throws when' => sub {
        ck { like( exception { $DUT->new }, qr/Need phase/ ) } 'phases are missing';
        ck { like( exception { $DUT->new('0') }, qr/phase.+truthy/ )} 'the only phase is 0' ;
        ck { like( exception { $DUT->new('') }, qr/phase.+truthy/) } 'the only phase is ""' ;
        ck { like( exception { $DUT->new(qw(0 x)) }, qr/phase.+truthy/)}  'the first phase is 0' ;
        ck { like( exception { $DUT->new(qw(x 0)) }, qr/phase.+truthy/)} 'the last phase is 0' ;
    };

    describe 'a single-phase sequence' => sub {
        my $dut;
        before all => sub { $dut = $DUT->new(qw(a)) };
        ck { isa_ok($dut, $DUT) };
        ck { is($dut->first, 'a') } 'has the right first element';
        ck { is($dut->last, 'a') } 'has the right last element';
        ck { ok(!$dut->next('a')) } 'has no elem after the first';
    };

    describe 'a two-phase sequence' => sub {
        my $dut;
        before all => sub { $dut = $DUT->new(qw(a b)) };
        ck { isa_ok($dut, $DUT) };
        ck { is($dut->first, 'a') } 'has the right first element';
        ck { is($dut->last, 'b') } 'has the right last element';
        ck { is($dut->next('a'), 'b') } 'has the right next(first)';
        ck { ok(!$dut->next('b')) } 'has no next(second)';
    };

    describe 'a three-phase sequence' => sub {
        my $dut;
        before all => sub { $dut = $DUT->new(qw(a b c)) };
        ck { isa_ok($dut, $DUT) };
        ck { is($dut->first, 'a') } 'has the right first element';
        ck { is($dut->last, 'c') } 'has the right last element';
        ck { is($dut->next('a'), 'b') } 'has the right next(first)';
        ck { is($dut->next('b'), 'c') } 'has the right next(second)';
        ck { ok(!$dut->next('c')) } 'has no next(third)';
    };

    describe 'a three-phase sequence with mixed original case' => sub {
        my $dut;
        before all => sub { $dut = $DUT->new(qw(Foo baR BAT)) };
        ck { isa_ok($dut, $DUT) };
        ck { is($dut->first, 'Foo') } 'has the right first element';
        ck { is($dut->last, 'BAT') } 'has the right last element';
        ck { is($dut->next('Foo'), 'baR') } 'has the right next(first)';
        ck { is($dut->next('baR'), 'BAT') } 'has the right next(second)';
        ck { ok(!$dut->next('BAT')) } 'has no next(third)';
    };
}; # new, first, last

# delayed_is(\$dut, method, arg, expect): ugly hack to be able to use
# is() calls inside loops.  Returns a sub to pass to is().
sub delayed_is {
    my ($dutref, $method, $arg, $expect) = @_;
    return sub { is($$dutref->$method($arg), $expect) };
}

# delayed_ok(\$dut, method, methodargs...): to use ok() in loops.
# is() calls inside loops.  Returns a sub to pass to is().
sub delayed_ok {
    my ($dutref, $method) = splice @_, 0, 2;
    my @rest = @_;
    return sub { ok($$dutref->$method(@rest)) };
}

context 'Check, enforce: ' => sub {
    my $dut;
    sueach { $dut = $DUT->new(qw(foo bar bat)) };
    ck { ok(!$dut->check('nonexistent')) } 'check: nonexistent phase fails';
    ck { like( exception { $dut->enforce('nonexistent') }, qr/Unknown.+nonexistent/ ) }
        'enforce: nonexistent phase fails';

    foreach my $phase (qw(foo FOO Foo fOo foO FOo FoO fOO)) {
        it "check: $phase" => delayed_is(\$dut, 'check', $phase, 'foo');
        it "enforce: $phase" => delayed_is(\$dut, 'enforce', $phase, 'foo');
    }

    foreach my $phase (qw(bar bat)) {
        it "check: $phase" => delayed_is(\$dut, 'check', $phase, $phase);
        it "enforce: $phase" => delayed_is(\$dut, 'enforce', $phase, $phase);
    }
};

context 'Is: ' => sub {
    my $dut;
    sueach { $dut = $DUT->new(qw(foo bar bat)) };
    it "$_ is foo" => delayed_ok(\$dut, 'is', $_, 'foo')
        foreach qw(foo FOO Foo fOo foO FOo FoO fOO);
    it "$_ matches when uppercased" => delayed_ok(\$dut, 'is', $_, uc $_) foreach qw(bar bat);
    ck { ok(!$dut->is('nonexistent', 'foo')) } 'nonexistent != foo';
    ck { ok(!$dut->is('foo', 'nonexistent')) } 'foo != nonexistent';
    ck { ok(!$dut->is('oops', 'nonexistent')) } 'oops != nonexistent';
};

# TODO RESUME HERE

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

test_next;
test_is_last;
test_all;

runtests;
