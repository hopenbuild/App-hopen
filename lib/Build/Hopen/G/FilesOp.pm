# Build::Hopen::G::FilesOp - Op that outputs a list of files.
package Build::Hopen::G::FilesOp;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000006'; # TRIAL

use parent 'Build::Hopen::G::Op';
use Class::Tiny {
    files => sub { [] },
};

# Docs {{{1

=head1 NAME

Build::Hopen::G::FilesOp - Op that holds a list of files.

=head1 SYNOPSIS

    my $node = Build::Hopen::G::FilesOp(files=>['foo.c'], name=>'foo node');

Used by L<Build::Hopen::H/files>.

=head1 FUNCTIONS

=cut

# }}}1

=head2 run

Output a C<work> record holding the given names.  See
L<Build::Hopen::Conventions/INTERNALS>.

=cut

sub run {
    my $self = shift or croak 'Need an instance';

    return { work => [ {
                from => [], how => undef,
                to => $self->files
            } ] };
} #run()

1;
__END__
# vi: set fdm=marker: #
