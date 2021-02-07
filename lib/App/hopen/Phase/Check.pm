# App::hopen::Phase::Check - Actions specific to the Check phase
package App::hopen::Phase::Check;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::Phase';
use Class::Tiny qw(TODO);

# Docs {{{1

=head1 NAME

App::hopen::Phase::Check - Actions specific to the Check phase

=head1 SYNOPSIS

TODO

=cut

# }}}1

=head1 METHODS

=cut

sub name { 'Check' }

sub make_myh {
    my $self = shift or croak 'Need an instance';

    my $build_graph_output = shift;

    my $config = extract_thunks($build_graph_output);
    my $VAR    = '__R_new_data';
    my $dumper = Data::Dumper->new([ $config, $build_graph_output ],
        [ 'Configuration', $VAR ]);
    $dumper->Pad(' ' x 12);       # To line up with the do{}
    $dumper->Indent(1);           # fixed indent size
    $dumper->Quotekeys(0);
    $dumper->Purity(1);
    $dumper->Maxrecurse(0);       # no limit
    $dumper->Sortkeys(true);      # For consistency between runs
    $dumper->Sparseseen(true);    # We don't use Seen()

    # Four-space indent instead of two-space.  This is using an undocumented
    # feature of Data::Dumper, whence the eval{}.
    eval { $dumper->{xpad} = ' ' x 4 };

    my $dumped = $dumper->Dump;
    my $separ  = '### Do not change below this line ' . ('#' x 45);
    $dumped =~ s{^(\h*)(\$__R_new_data\h*=)}{\n$1$separ\n\n$1$2}m;

    return dedent [], qq(
        do {
            my (\$Configuration, \$$VAR);
$dumped
            dethunk(\$$VAR);
            \$$VAR
    );

    # Notes on the above $new_text:
    # - No semi after the Dump line --- Dump adds it automatically.
    # - Dump() may produce multiple statements, so add the
    #   express $__R_new_data at the end so the do{} will have a
    #   consistent return value.
    # - The Dump() line is not indented because it does its own indentation.
} ## end sub make_myh

1;
__END__
# vi: set fdm=marker: #
