# App::hopen::G::Cmd - base class for hopen(1) command-graph nodes
package App::hopen::G::Cmd;
use strict; use warnings;
use Data::Hopen::Base;
use Quote::Code;

our $VERSION = '0.000013'; # TRIAL

use parent 'Data::Hopen::G::Op';
use Class::Tiny {
    made => sub { [] },
};

use App::hopen::AppUtil qw(:constants);
use Class::Method::Modifiers qw(around);
use Data::Hopen qw(getparameters);

# Docs {{{1

=head1 NAME

App::hopen::G::Cmd - base class for hopen(1) command-graph nodes

=head1 SYNOPSIS

This is the base class for graph nodes in the command graph of
L<App::hopen>.  See L<App::hopen::Manual>.

=head1 ATTRIBUTES

=head2 made

An arrayref of the outputs from this function, which are L<App::hopen::Asset>
instances.

=cut

# }}}1

=head1 FUNCTIONS USABLE WHILE RUNNING

The following functions are only usable during C<_run()>
(see L<Data::Hopen::G::Runnable/_run>.

=head2 getphase

Returns the current phase
TODO die if there is no current phase.

    my $thisphase = $self->getphase;

=cut

sub getphase {
    return PHASES->enforce(shift->scope->find(KEY_PHASE)//'');
}

=head2 make

Adds L<App::hopen::Asset> instances to L</made> (a Cmd's asset output).
B<Does not> add the assets to the generator's asset graph, since the asset graph
(if any) is an implementation detail of the generator.  Always returns undef
so it can be used as the last statement in a _run function.

One or more parameters or arrayrefs of parameters can be given.  Each parameter
can be:

=over

=item *

An L<App::hopen::Asset> or subclass

=item *

A valid C<target|App::hopen::Asset/target> for an L<App::hopen::Asset>.

=back

=cut

sub make {
    my $self = shift or croak 'Need an instance';
    push @{$self->made}, $self->_assets_for(@_);
    return undef;
} #make()

# Recursively collect assets to be made
sub _assets_for {
    my $self = shift;
    my @retval;
    for my $arg (@_) {
        if(ref $arg eq 'ARRAY') {
            push @retval, $self->_assets_for(@$arg);
        } elsif(eval { $arg->DOES('App::hopen::Asset') }) {
            push @retval, $arg;
        } else {
            my $asset = App::hopen::Asset->new(target=>$arg);
            push @retval, $asset;
        }
    } #foreach arg
    return @retval;
} # _assets_for()

=head2 input_assets

Returns the assets provided as input via L</make> calls in predecessor nodes.
Only meaningful within C<_run()> (since that's when C<< $self->scope >>
is populated).  Returns an arrayref in scalar context or a list in list context.

=cut

sub input_assets {
    my $self = shift or croak 'Need an instance';
    my $lrSourceFiles;

    my $hrSourceFiles =
        $self->scope->find(-name => 'made', -set => '*', -levels => 'local') // {};

    if(keys %$hrSourceFiles) {
        $lrSourceFiles = $hrSourceFiles->{(keys %$hrSourceFiles)[0]};
    } else {
        $lrSourceFiles = [];
    }

    return $lrSourceFiles unless wantarray;
    return @$lrSourceFiles;
} #input_assets()

=head1 FUNCTIONS USABLE ANY TIME

=head2 language

Returns the source language with which this Cmd is associated, or falsy if
none.  The implementation in C<Cmd> is for use with the layout of
L<App::hopen::Manual>: if the class name is of the form
 C<< App::hopen::T::<toolset>::<language> >>, C<< <language> >> is returned.
May be overridden by subclasses.

=cut

sub language {
    my $self = shift;
    my $class = ref $self;
    return $1 if $class =~ m{^App::hopen::T::[^:]+::([^:]+)};
    die "Can't find a language type in class name $class";
} #language()

=head2 run

Wraps L<Data::Hopen::G::Runnable/run> to stuff L</made> into the
outputs if it's not already there.  Note that this will B<replace>
any non-arrayref C<made> output.

=cut

around 'run' => sub {
    my $orig = shift;
    my $self = shift or croak 'Need an instance';
    my $retval = $self->$orig(@_);

    $retval->{made} = $self->made unless ref $retval->{made} eq 'ARRAY';
        # TODO clone?  Shallow copy?
    return $retval;
}; #run()

1;
__END__
# vi: set fdm=marker: #
