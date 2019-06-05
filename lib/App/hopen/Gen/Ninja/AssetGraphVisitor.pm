# App::hopen::Gen::Ninja::AssetGraphVisitor - visitor to write goals
package App::hopen::Gen::Ninja::AssetGraphVisitor;
use Data::Hopen qw(hlog getparameters $VERBOSE);
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000012'; # TRIAL

use parent 'Data::Hopen::Visitor';
use Class::Tiny;

use App::hopen::BuildSystemGlobals;     # for $DestDir
use App::hopen::Gen::Ninja::AssetGraphNode;     # for OUTPUT
use Quote::Code;

# Docs {{{1

=head1 NAME

App::hopen::Gen::Ninja::AssetGraphVisitor - visitor to write goals

=head1 SYNOPSIS

This is the visitor used when L<App::hopen::Gen::Ninja> traverses the
asset graph.  Its purpose is to tie the inputs to each goal into that goal.

=head1 FUNCTIONS

=cut

# }}}1

=head2 visit_goal

Write a goal entry to the Ninja file being built.
This happens while the asset graph is being run.

=cut

sub visit_goal {
    my ($self, %args) = getparameters('self', [qw(goal node_inputs)], @_);
    my $fh = $args{node_inputs}->find(App::hopen::Gen::Ninja::AssetGraphNode::OUTPUT);

    # Pull the inputs.  TODO refactor out the code in common with
    # AhG::Cmd::input_assets().
    my $hrInputs =
        $args{node_inputs}->find(-name => 'made',
                                    -set => '*', -levels => 'local') // {};
    die 'No input files to goal ' . $args{goal}->name
        unless scalar keys %$hrInputs;

    my $lrInputs = $hrInputs->{(keys %$hrInputs)[0]};
    hlog { __PACKAGE__, 'found inputs to goal', $args{goal}->name, Dumper($lrInputs) } 2;

    my @paths = map { $_->target->path_wrt($DestDir) } @$lrInputs;
    say $fh qc'\n# === Ninja file goal {$args{goal}->name}' if $VERBOSE;
    say $fh qc'build {$args{goal}->name}: phony {join " ", @paths}';
    say $fh qc'default {$args{goal}->name}';
} #visit_goal()

=head2 visit_node

No-op.

=cut

sub visit_node { }

1;
__END__
# vi: set fdm=marker: #
