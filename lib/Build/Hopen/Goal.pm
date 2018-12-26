# Build::Hopen::Goal - A named build goal
package Build::Hopen::Goal;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000001';

use parent 'Build::Hopen::Node';
use Class::Tiny;

# Docs {{{1

=head1 NAME

Build::Hopen::Goal - a named goal in a hopen build

=head1 SYNOPSIS

A C<Goal> is a named build target, e.g., C<doc> or C<dist>.  The name C<all>
is reserved for the root goal.

=cut

# }}}1

1;
__END__
# vi: set fdm=marker: #
