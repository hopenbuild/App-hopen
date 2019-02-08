# Build::Hopen::G::Goal - A named build goal
package Build::Hopen::G::Goal;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000007'; # TRIAL

use parent 'Build::Hopen::G::Op';
#use Class::Tiny qw(_passthrough);

use Build::Hopen::Arrrgs;
use Build::Hopen::Util::Data qw(forward_opts);

# Docs {{{1

=head1 NAME

Build::Hopen::G::Goal - a named goal in a hopen build

=head1 SYNOPSIS

A C<Goal> is a named build target, e.g., C<doc> or C<dist>.  The name C<all>
is reserved for the root goal.  Goals usually appear at the end of the build
graph, but this is not required --- Goal nodes can appear anywhere in the
graph.

=head1 FUNCTIONS

=head2 run

Wraps a L<Build::Hopen::G::CollectOp>'s run function.

=cut

# }}}1

sub _run {
    my ($self, %args) = parameters('self', [qw(; phase generator)], @_);
    hlog { Goal => $self->name };
    return $self->passthrough(-nocontext=>1, -levels => 'local',
            forward_opts(\%args, {'-'=>1}, qw[phase generator]));
} #_run()

=head2 BUILD

Enforce the requirement for a user-specified name.

=cut

sub BUILD {
    my ($self, $args) = @_;
    croak 'Goals must have names' unless $args->{name};
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
