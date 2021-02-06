# App::hopen::MYhopen - module for managing MY.hopen.pl files
package App::hopen::MYhopen;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use App::hopen::Util;

use parent 'Exporter';
use vars::i {
    '@EXPORT'    => [qw(extract_thunks)],
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
files.  See L<App::hopen::HopenFileKit> for functions used within MY.hopen.pl
files, such as for setting the phase.

=cut

# }}}1

=head2 extract_thunks

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

1;
__END__
# vi: set fdm=marker: #
