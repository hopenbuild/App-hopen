# App::hopen::H - H:: namespace for use in hopen files
package App::hopen::H;
use Data::Hopen::Base;

our $VERSION = '0.000009'; # TRIAL

use parent 'Exporter';
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw();
    @EXPORT_OK = qw(files);
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

use App::hopen::G::FilesOp;
use Data::Hopen qw(hlog getparameters);
use Data::Hopen::G::GraphBuilder;
use Data::Hopen::Util::Data qw(forward_opts);
use Path::Class;

# Docs {{{1

=head1 NAME

Data::Hopen::H - H:: namespace for use in hopen files

=head1 SYNOPSIS

This module is loaded as C<H::*> into hopen files by
L<Data::Hopen::HopenFileKit>.

=head1 FUNCTIONS

=cut

# }}}1

=head2 files

Creates a DAG node representing a set of input files.  Example usage:

    $Build->H::files('foo.c')->C::compile->C::link('foo')->default_goal;

The node is a L<Data::Hopen::G::FilesOp>.

=cut

sub files {
    my ($builder, %args) = getparameters('self', ['*'], @_);
    hlog { __PACKAGE__, 'files:', Dumper(\%args) } 3;
    return App::hopen::G::FilesOp->new(
        files => [ map { file($_)->absolute } @{$args{'*'} // []} ],
        forward_opts(\%args, 'name')
    );
} #files()

make_GraphBuilder 'files';

1;
__END__
# vi: set fdm=marker: #
