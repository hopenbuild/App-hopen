# App::hopen::Lang::C - LSP for C
package App::hopen::Lang::C;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

use parent 'App::hopen::Lang';
use Class::Tiny;

use Capture::Tiny qw(capture);

# Docs {{{1

=head1 NAME

App::hopen::Lang::C - LSP for C

=head1 SYNOPSIS

TODO

=cut

# }}}1

=head1 FUNCTIONS

=head2 find_deps

Find C dependencies.  The return hashref has keys C<ipath> (like -I),
C<lpath> (-L), and C<lname> (-l).  Each key has an arrayref as its value.
Usage:

    my $hrLangOpts = $lang->find_deps(\%deps, $required[, \%choices]);

=cut

sub find_deps {
    my ($self, %args) = getparameters('self', [qw(deps required ; choices)], @_);
    # TODO RESUME HERE ---
    # 1. Create the infrastructure for choices and add that infrastructure
    #    to MY.hopen.pl.
    # 2. Run pkg-config here for libraries and parse the results

    my $retval = { ipath => [], lpath => [], lname => [] };   # TODO

    foreach my $ty (keys %{$args{deps}}) {
        if($ty eq '-lib') {
            foreach my $lib (@{$args{deps}->{$ty}}) {
                my ($stdout, $stderr, $result) = capture {
                    system {'pkg-config'} qw(pkg-config --cflags --libs), $lib
                };
                if($result != 0) {
                    my $msg = "Could not find dependency $lib: $stderr";
                    die $msg if $args{required};
                    warn $msg;
                    next;
                }
                hlog { "pkg-config $lib returned >>$stdout<<" };

                while(my ($which, $what) = ($stdout =~ m{\G.*?-([IlL])(\S+)}gmsc)) {
                    state %map = (I=>'ipath', l => 'lname', L => 'lpath');
                    my $k = $map{$which} or die "programmer error";
                    push @{$retval->{$k}}, $what;
                }
            };
        } else {
            die "Unknown dependency type $ty for " . __PACKAGE__;
        }
    }
    hlog { __PACKAGE__, 'dependencies for', Dumper($self->{deps}),
        'are', Dumper($retval) } 2;

    return $retval;
} #find_deps()

1;
__END__
# vi: set fdm=marker: #
