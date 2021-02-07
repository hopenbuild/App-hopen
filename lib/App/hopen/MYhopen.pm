# App::hopen::MYhopen - module for managing MY.hopen.pl files
package App::hopen::MYhopen;
use Data::Hopen qw(:default loadfrom);
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use App::hopen::AppUtil ':all';
use App::hopen::Util;
use App::hopen::Util::String ':all';

use parent 'Exporter';
use vars::i {
    '@EXPORT'    => [qw(dethunk extract_thunks load_phase set_phase_text)],
    '@EXPORT_OK' => [qw()],
};
use vars::i '%EXPORT_TAGS' => (
    default => [@EXPORT],
    all     => [ @EXPORT, @EXPORT_OK ]
);

# Docs {{{1

=head1 NAME

App::hopen::MYhopen - module for managing MY.hopen.pl files

=head1 SYNOPSIS

This module contains routines used to read, write, and process MY.hopen.pl
files.  See L<App::hopen::HopenFileKit> and L<App::hopen::H> for functions used
within MY.hopen.pl files, such as for setting the phase.

=head1 FUNCTIONS

=cut

# }}}1

=head2 Configuration Data

These functions are used in managing configuration data.

=head3 dethunk

Walk a hashref and replace all the L<App::hopen::Util::Thunk> instances with
their L<tgt|App::hopen::Util::Thunk/tgt>s.  Operates in-place.  Usage:

    dethunk(\%config, \%data)

See L<App::hopen::MYhopen/extract_thunks> for creating C<%config>.

=cut

our $_config;

sub dethunk {
    my $data = shift;
    die "need a data arrayref or hashref" unless isaggref $data;

    _dethunk_walk($data);
} ## end sub dethunk

# Dethunk.  Can't use Data::Walk because of <https://github.com/gflohr/Data-Walk/issues/2>.
# Precondition: $node is an arrayref or hashref
sub _dethunk_walk {
    my $node   = shift;
    my $ty     = ref $node;
    my $ishash = $ty eq 'HASH';

    my @kids;

    if($ishash) {
        foreach my $k (keys %$node) {
            my $v = $node->{$k};
            hlog { Value => $v } 5;
            if(ref $v eq 'App::hopen::Util::Thunk') {
                hlog { Dethunk => $v->name } 4;
                $v = $node->{$k} = $v->tgt;
            }
            push @kids, $v if isaggref $v;
        } ## end foreach my $k (keys %$node)

    } else {    # array
        foreach my $pair (map { [ $_, $node->[$_] ] } 0 .. $#$node) {
            my ($i, $v) = @$pair;
            hlog { Value => $v } 5;
            if(ref $v eq 'App::hopen::Util::Thunk') {
                hlog { Dethunk => $v->name } 4;
                $v = $node->[$i] = $v->tgt;
            }
            push @kids, $v if isaggref $v;
        } ## end foreach my $pair (map { [ $_...]})
    } ## end else [ if($ishash) ]

    _dethunk_walk($_) foreach @kids;
} ## end sub _dethunk_walk

=head3 extract_thunks

Pull out any L<App::hopen::Util::Thunk> instances from a hashref or arrayref
and return a hashref suitable for use as config.  Usage:

    my $in = <some arrayref or hashref>;
    my $config = extract_thunks($in);

NOTE: May mutate Thunks in the input.  Specifically, it will adjust thunk
names so they are all unique.  TODO figure out if this is the Right Thing!
What if multiple nodes need the same config value?

See L<App::hopen::HopenFileKit/dethunk> for using C<$config> to fill in
values in the input.

=cut

sub extract_thunks {
    my $data = shift;
    die "need a data arrayref or hashref" unless isaggref $data;
    my $retval = +{};

    _extract_thunks_walk($retval, $data);
    return $retval;
} ## end sub extract_thunks

# Make a key that doesn't exist in a hashref.
# Usage: $newname = _make_unique_in($hr, $oldname)
sub _make_unique_in {
    state $uniq_idx = 1;

    my ($hash, $k) = @_;
    return $k unless exists $hash->{$k};
    ++$uniq_idx while exists $hash->{ $k . $uniq_idx };
    return $k . $uniq_idx;
} ## end sub _make_unique_in

# Process a thunk.  Params: \%retval, $thunk
sub _etw_process {
    my ($retval, $v) = @_;
    my $n = $v->name;
    hlog { 'Found thunk', $n } 4;

    # TODO implement namespaced names
    $n = _make_unique_in($retval, $n);
    $v->name($n);
    $retval->{$n} = $v->tgt;
} ## end sub _etw_process

# Preconditions: $retval is a hashref; $node is an arrayref or hashref
sub _extract_thunks_walk {

    my ($retval, $node) = @_;
    my $ty     = ref $node;
    my $ishash = $ty eq 'HASH';

    my @kids;

    if($ishash) {
        foreach my $k (sort keys %$node) {    # sort for reproducibility
            my $v = $node->{$k};
            hlog { Value => $v } 5;
            if(ref $v eq 'App::hopen::Util::Thunk') {
                _etw_process($retval, $v);
                push @kids, $v->tgt if isaggref($v->tgt);
            }
            push @kids, $v if isaggref($v);
        } ## end foreach my $k (sort keys %$node)

    } else {    # array
        foreach my $pair (map { [ $_, $node->[$_] ] } 0 .. $#$node) {
            my ($i, $v) = @$pair;
            hlog { Value => $v } 5;
            if(ref $v eq 'App::hopen::Util::Thunk') {
                _etw_process($retval, $v);
                push @kids, $v->tgt if isaggref($v->tgt);
            }
            push @kids, $v if isaggref($v);
        } ## end foreach my $pair (map { [ $_...]})
    } ## end else [ if($ishash) ]

    _extract_thunks_walk($retval, $_) foreach @kids;
} ## end sub _extract_thunks_walk

=head2 Phase support

These functions relate to setting the phase.

=head3 load_phase

Load the L<App::Hopen::Phase> subclass for the given phase name, or die.
Returns the phase instance.

=cut

sub load_phase {
    my $phasename = PHASES->enforce(shift);

    my $phaseclass = loadfrom($phasename, 'App::hopen::Phase::');
    croak "I don't know how to handle phase $phasename" unless $phaseclass;
    return $phaseclass->new;
} ## end sub load_phase

=head3 set_phase_text

Returns the source text for use in MYH files for function C<set_phase> and
related.  Assumes that L<App::hopen::HopenFileKit> has been loaded in the
hopen file.

Usage: C<< my $text = set_phase_text(%opts); >>.  Valid keys in C<%opts> are:

=over

=item C<instancename>

(Required) Fully-qualified (but no sigil) name of the variable in the MYH
file that represents the App::hopen instance.

=item C<phase_locked>

(Optional) If given with a truthy value, C<set_phase()> is a no-op.

=item C<only_warn>

(Optional; only takes effect when C<phase_locked> is true) If given with a
truthy value, attempts to change the phase warn.  Otherwise, attempts to change
the phase are fatal.

=back

Note: all phase-setting functions succeed if there was nothing for them to do!

=cut

sub set_phase_text {
    my %opts = @_;

    if(!$opts{phase_locked}) {
        croak "instancename option is required" unless $opts{instancename};

        my $set_phase = line_mark_string <<'EOT';
            sub _mark_phase_as_set;
            sub can_set_phase { true }
            sub set_phase {
                my $new_phase = shift or croak 'Need a phase';
                return if $Phase->is($new_phase);
                $new_phase = PHASES->enforce($new_phase);
                require App::hopen::MYhopen;
                require App::hopen::BuildSystemGlobals;
                $Phase = $App::hopen::BuildSystemGlobals::Phase =
                    App::hopen::MYhopen::load_phase($new_phase);
                _mark_phase_as_set;
                say "Running $new_phase phase" unless $QUIET;
            }
EOT

        $set_phase .= line_mark_string __FILE__, __LINE__,
            'sub _mark_phase_as_set { $'
          . $opts{instancename}
          . "->did_set_phase(true) }\n";

        return $set_phase;

    } elsif(!$opts{only_warn}) {
        my $cannot_set_phase = line_mark_string <<'EOT';
            sub can_set_phase { false }
            sub set_phase {
                my $new_phase = shift // '';
                return if $Phase->is($new_phase);
                croak "I'm sorry, but this file (``$FILENAME'') is not allowed to set the phase";
            }
EOT
        return $cannot_set_phase;

    } else {
        my $cannot_set_phase_warn = line_mark_string <<'EOT';
            sub can_set_phase { false }
            sub set_phase {
                my $new_phase = shift // '';
                return if $Phase->is($new_phase);
                unless($QUIET) {
                    warn "``$FILENAME'': Ignoring attempt to set phase $new_phase, " .
                    "since phase @{[$Phase->name]} was given on the command line\n";
                }
            }
EOT
        return $cannot_set_phase_warn;
    } ## end else [ if(!$opts{phase_locked...})]
} ## end sub set_phase_text

1;
__END__
# vi: set fdm=marker: #
