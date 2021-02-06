# App::hopen::T::Gnu::C::CompileCmd - compile C source using the GNU toolset
package App::hopen::T::Gnu::C::CompileCmd;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::G::OutputPerFileCmd';
use Class::Tiny qw(compiler);

use App::hopen::AppUtil qw(:constants);
use App::hopen::Asset;
use App::hopen::BuildSystemGlobals;    # For $DestDir.
    # TODO make the dirs available to nodes through the context.
use App::hopen::Util::BasedPath;
use App::hopen::Util::Thunk;
use Data::Hopen qw(getparameters);
use Data::Hopen::Util::Filename;
use Path::Class;

my $_FN = Data::Hopen::Util::Filename->new;    # for brevity

# Docs {{{1

=head1 NAME

App::hopen::T::Gnu::C::CompileCmd - compile C source using the GNU toolset

=head1 SYNOPSIS

In a hopen file:

    my $cmd = App::hopen::T::Gnu::C::CompileCmd->new(
        compiler => '/usr/bin/gcc',
        name => 'compilation command'   # optional
    );

The inputs come from earlier in the build graph.
TODO support specifying compiler arguments.

=head1 ATTRIBUTES

=head2 compiler

The compiler to use.  TODO is this a full path or just a name?

=head1 MEMBER FUNCTIONS

=cut

# }}}1

=head2 Check

Create a config entry for the compiler

=cut

sub Check {
    my $self = shift;

    my $name = 'compiler @ App::hopen::T::Gnu';
    $self->_stash->{$name} = App::hopen::Util::Thunk->new(
        tgt  => [ $self->compiler ],
        name => $name
    );
} ## end sub Check

=head2 Gen

Create the compile command line for a given asset.

=cut

sub Gen {
    my ($self, %args) = getparameters('self', [qw(asset; *)], @_);
    my $src = $args{asset};

    die "Cannot compile non-file $src" unless $src->isdisk;

    my $to = based_path(
        path => file($_FN->obj($src->target->path)),
        base => $DestDir
    );
    my $how = $self->compiler . " -c #first -o #out";
    my $obj = App::hopen::Asset->new(
        target => $to,
        how    => $how,
    );

    return $obj;
} ## end sub Gen

1;
__END__
# vi: set fdm=marker: #
