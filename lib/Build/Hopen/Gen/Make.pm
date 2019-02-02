# Build::Hopen::Gen::Make - generator for a generic make(1).
package Build::Hopen::Gen::Make;
use Build::Hopen;
use Build::Hopen::Base;
use parent 'Exporter';

our $VERSION = '0.000005'; # TRIAL

use Hash::Ordered;

use parent 'Build::Hopen::Gen';
use Class::Tiny {
    targets => sub { Hash::Ordered->new() }
};

# Docs {{{1

=head1 NAME

Build::Hopen::Gen::Make - hopen generator for simple Makefiles

=head1 SYNOPSIS

This generator makes a Makefile that does its best to run on cmd.exe or sh(1).

=head1 ATTRIBUTES

=head2 targets

A L<Hash::Ordered> of the targets, in the order encountered.

=head1 FUNCTIONS

=cut

# }}}1

=head2 visit_goal

Add a target corresponding to the name of the goal.

=cut

sub visit_goal {
    my $self = shift or croak 'Need an instance';
    my $goal = shift or croak 'Need a goal';
    $self->targets->set($goal->name, $goal);
} #visit_goal()

#=head2 visit_node
#
#TODO
#
#=cut
#
#sub visit_node {
#    my $self = shift or croak 'Need an instance';
#    ...
#} #visit_node()

=head2 finalize

Write out the Makefile.

=cut

sub finalize {
    # TODO return unless Gen phase
    my $self = shift or croak 'Need an instance';
    open my $fh, '>', $self->dest_dir->file('Makefile') or die "Couldn't create Makefile";

    my $iter = $self->targets->iterator;
    while( my ($name, $goal) = $iter->() ) {
        say $fh "$name:";
        say $fh "\techo \"$name\"";
        say $fh '';
    }
    close $fh;
} #finalize()

=head2 default_toolset

Returns the package name of the default toolset for this generator,
which is C<Gnu> (i.e., L<Build::Hopen::T::Gnu>).

=cut

sub default_toolset { 'Gnu' }

1;
__END__
# vi: set fdm=marker: #
