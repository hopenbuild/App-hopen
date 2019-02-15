# App::hopen::G::FilesOp - Op that outputs a list of files.
package App::hopen::G::FilesOp;
#use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000009'; # TRIAL

use parent 'Data::Hopen::G::Op';
use Class::Tiny {
    files => sub { [] },
};

# Docs {{{1

=head1 NAME

Data::Hopen::G::FilesOp - Op that holds a list of files.

=head1 SYNOPSIS

    my $node = Data::Hopen::G::FilesOp(files=>['foo.c'], name=>'foo node');

Used by L<Data::Hopen::H/files>.

=head1 FUNCTIONS

=cut

# }}}1

=head2 run

Output a C<work> record holding the given names.  See
L<Data::Hopen::Conventions/INTERNALS>.

=cut

sub _run {
    my $self = shift or croak 'Need an instance';

    return { work => [ {
                from => [], how => undef,
                to => $self->files
            } ] };
} #run()

1;
__END__
# vi: set fdm=marker: #
