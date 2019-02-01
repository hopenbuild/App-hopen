# Build::Hopen::G::GraphBuilder - fluent interface for building graphs
package Build::Hopen::G::GraphBuilder;
use Build::Hopen;
use Build::Hopen::Base;
use Exporter 'import';

our @EXPORT; BEGIN { @EXPORT=qw(GraphBuilder MODIFY_CODE_ATTRIBUTES); }

our $VERSION = '0.000005'; # TRIAL

use Class::Tiny {
    name => sub { 'ANON' },     # Name is optional; it's here so the
                                # constructor won't croak if you use one.

    dag => undef,
    node => undef,
};

use Sub::Attribute;

# Docs {{{1

=head1 NAME

Build::Hopen::G::GraphBuilder - fluent interface for building graphs

=head1 SYNOPSIS

A GraphBuilder wraps a L<Build::Hopen::G::DAG> and a current
L<Build::Hopen::G::Node>.  It permits building chains of nodes in a
fluent way.  For example, in a hopen file:

    # $Build is a Build::Hopen::G::DAG
    use language 'C';

    my $builder = $Build->C::compile(file => 'foo.c');
        # Now $builder holds $Build (the DAG) and a node created by
        # C::compile().

=head1 ATTRIBUTES

=head2 name

An optional name, in case you want to identify your Builder instances.

=head2 dag

The current L<Build::Hopen::G::DAG> instance, if any.

=head2 node

The current L<Build::Hopen::G::Node> instance, if any.

=head1 STATIC FUNCTIONS

=cut

# }}}1

=head2 GraphBuilder

A subroutine attribute that wraps the given subroutine so that it can
take a DAG or a builder.

=cut

sub GraphBuilder :ATTR_SUB {
    my($class, $sym_ref, $code_ref, $attr_name, $attr_data) = @_;

    local *wrapper = sub {
        croak "Need a parameter" unless @_;
        my $first = shift;
        $first = __PACKAGE__->new(dag=>$first)
            unless $first->DOES(__PACKAGE__);
        croak "Parameter must be a DAG or Builder"
            unless $first->dag->DOES('Build::Hopen::G::DAG');

        unshift @_, $first;
        &{$code_ref};   # @_ passed to code
    }; #wrapper()

    say Dumper(\&wrapper);
    say Dumper($sym_ref);

    # Thanks for syntax to
    # https://metacpan.org/source/JIMBOB/Memoize-Memcached-Attribute-0.11/lib/Memoize/Memcached/Attribute.pm#L63
    my $symbol_name = join('::', $class, *{ $sym_ref }{NAME});
    say $symbol_name;

    {
        no warnings 'redefine';
        no strict 'refs';
        *{$symbol_name} = \&wrapper;
    }
} #todo()

1;
__END__
# vi: set fdm=marker: #
