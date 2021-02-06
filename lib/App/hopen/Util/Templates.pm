# App::hopen::Util::Templates - load and render templates from a __DATA__ section
# TODO use Text::Template instead of Text::MicroTemplate?
package App::hopen::Util::Templates;
use Data::Hopen qw(getparameters hlog);
use strict;
use warnings;
use Data::Hopen::Base;

use App::hopen::Util::String qw(line_mark_string);
use Data::Section::Simple;
use Text::MicroTemplate;

our $VERSION = '0.000013';    # TRIAL

use Class::Tiny {
    source => undef,          # package we get templates from

    # Cache templates from __DATA__ since Data::Section::Simple doesn't
    _templates => undef,

    # Cache renderers
    _renderers    => sub { +{} },
    _renderer_idx => 0,             # for making renderer package names
};

# Docs {{{1

=head1 NAME

App::hopen::Util::Templates - load and render templates from a __DATA__ section

=head1 SYNOPSIS

    use App::hopen::Util::Templates;
    my %args = (answer => 42);
    my $result = template('supertemplate')->(%args);
    print $result;      # "Answer: 42"

    1;
    __DATA__
    @@ supertemplate
    Answer: <?= $v{answer} ?>

=head1 DESCRIPTION

=head2 Importing

When imported, this module creates a function C<template> in your package.
Given the name of a L<Text::MicroTemplate> template in your package's
C<__DATA__> section, that function returns the template object, ready to
be invoked.

To change the name of the function, pass it as an argument to C<use>.  E.g.:

    use App::hopen::Util::Templates qw(custom);
    my $result = custom('supertemplate')->(foo => 1);

=head2 Defining templates

    __DATA__
    @@ template_name_1
    Contents 1

    @@ template_name_2
    Contents 2 <?= $v{some_parameter} ?>

The C<@@> lines come from L<Data::Section::Simple>.  The C<< <? ?> >> tags
for template substitutions and embedded code come from
L<Text::MicroTemplate>.

=head2 Calling templates

The C<template()> function returns a coderef you call to render the template.

If you call that coderef with a hashref or a hash, the contents of that
hashref or has will be available in the template as C<%v> (for B<v>ars).

If the output from the template has more than one trailing newline,
only one will be kept.  This is so you can leave blank lines between
the templates in the C<__DATA__> section.

=cut

# }}}1

=head1 FUNCTIONS

=cut

# Get the package name for the next renderer
sub _renderer_pkg {
    my $self = shift;
    my $name = '__R_TemplateRenderer_' . $self->_renderer_idx;
    $self->_renderer_idx($self->_renderer_idx + 1);
    return $name;
} ## end sub _renderer_pkg

# Create a template.  This is the meat of the template() function.
sub _get_template {
    my ($self, %args) = getparameters('self', [qw(which)], @_);
    my $name = $args{which};

    # Lazy-load DATA section since the DATA filehandle doesn't exist
    # when this module is `use`d.
    unless($self->_templates) {
        my $dss = Data::Section::Simple->new($self->source);
        $self->_templates($dss->get_data_section);
    }

    unless($self->_renderers->{$name}) {
        die "No template $name found in package @{[$self->source]}"
          unless exists $self->_templates->{$name};

        # Thanks to the T::MT docs for this workflow
        my $code = Text::MicroTemplate->new(
            template     => $self->_templates->{$name},
            escape_func  => undef,
            package_name => $self->_renderer_pkg,
        )->code;
        my $str = line_mark_string <<"EOT";
            sub {
                my %v;  # basic variable unpacking
                if(ref \$_[0] eq 'HASH') {  # accept a hashref...
                    %v = %{\$_[0]};
                } elsif(!(\@_ % 2)) {       # ...or a hash.
                    %v = \@_;
                }
                my \$result = $code->();
                \$result =~ s/\\n+\\z/\\n/s;
                return \$result;
            }
EOT
        $self->_renderers->{$name} = eval $str;
        die "Could not create template $name: $@" if $@;
        hlog { "Template renderer code for $name:\n", $str } 3;
    } ## end unless($self->_renderers->...)
    return $self->_renderers->{$name};
} ## end sub _get_template

=head2 import

Create C<template()>.  If an argument is given, use that name instead
of C<template>.

=cut

sub import {
    my $class  = shift;
    my $target = caller;
    my $self   = $class->new(source => $target);
    my $fnname = $_[0] || 'template';

    {
        no strict 'refs';
        *{ $target . '::' . $fnname } = sub { $self->_get_template(@_) };
        hlog { "Added $fnname\() to $target" } 4;
    }
} ## end sub import

1;
__END__

# Docs {{{1

=head1 AUTHOR

Christopher White, C<cxwembedded at gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018--2020 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut

# }}}1
# vi: set fdm=marker: #
