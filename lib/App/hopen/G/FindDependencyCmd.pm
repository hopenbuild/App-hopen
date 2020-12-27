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

# Docs {{{1

=head1 NAME

App::hopen::G::FindDependencyCmd - Cmd that finds a dependency

=head1 SYNOPSIS

    my $node = App::hopen::G::FindDependencyCmd->new(deps => { WHAT => [WHICH] },
        name=>'foo node');

where C<WHAT> is, e.g., C<library>, and C<WHICH> is a name or list of names.

Used by L<App::hopen::H/want>.

=head1 ATTRIBUTES

=head2 deps

Hash of arrayrefs.  E.g.:

    { library => [qw(foo bar)], other_type => ['some name'] }

=head1 FUNCTIONS

=cut

# }}}1

=head2 _run

TODO

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(phase visitor ; *)], @_);

    ...

    my @assets = $self->make(@{$self->files});
    $args{visitor}->asset($_) foreach @assets;

    return {TODO => 'TODO'};
} #run()

1;
__END__
# vi: set fdm=marker: #
