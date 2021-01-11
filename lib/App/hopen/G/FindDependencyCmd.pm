# App::hopen::G::FindDependencyCmd - Cmd that finds a dependency
package App::hopen::G::FindDependencyCmd;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

use parent 'App::hopen::G::Cmd';
use Class::Tiny {
    deps => sub { +{} },
    required => false,
};

use App::hopen::Asset;
use Data::Dumper;

# Docs {{{1

=head1 NAME

App::hopen::G::FindDependencyCmd - Cmd that finds a dependency

=head1 SYNOPSIS

    my $node = App::hopen::G::FindDependencyCmd->new(deps => { WHAT => [WHICH] },
        name=>'foo node');

where C<WHAT> is, e.g., C<library>, and C<WHICH> is a name or list of names.
If you also pass C<< required => true >>, the command will abort if the
dependency is not found.

Used by L<App::hopen::H/want>.

=head1 ATTRIBUTES

=head2 deps

Hash of arrayrefs.  E.g.:

    { library => [qw(foo bar)], other_type => ['some name'] }

=head2 required

Whether the listed L</deps> are required.

=head1 METHODS

=cut

# }}}1

=head2 _run

In the Check phase:

=over

=item 1.

Look down the graph and see what languages we need.  Make the options for those
languages.

=item 2.

Try to find the dependencies and fill in the options.  Warn if non-required
packages are not found.

=back

In the Gen phase:

=over

=item 1.

Get the option values and confirm that we can find them.  Die if not, and
if L</required>.

=item 2.

Pass the values down the chain.

=back

=cut

my %fns = (
    'check' => \&_check,
    'gen' => \&_gen,
);

sub _run {
    my ($self, %args) = getparameters('self', [qw(; visitor graph *)], @_);
    # TODO refactor to use PhaseManager
    my $thisphase = lc($self->getphase);

    my $fn = $fns{$thisphase} // sub {};
    return $fn->($self, %args);
} #_run()

# --- Workers for _run() ---

sub _check {
    my ($self, %args) = @_;

    my @successors = $args{graph}->_graph->all_successors($self);
    hlog { 'Successors of', $self->name, Dumper([map { $_->name } @successors]) } 3;
    my %langs;
    foreach(@successors) {
        my $lang = eval { $_->language };
        next unless $lang;
        $langs{$lang} = 1;
    }

    hlog { 'Languages in use:', join ', ', keys %langs };

    return undef #{TODO => TODO};
} # _check()

sub _gen {
    my ($self, %args) = @_;
    return undef #{TODO => TODO};
} # _gen()

1;
__END__
# vi: set fdm=marker: #
