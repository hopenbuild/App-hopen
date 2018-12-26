# Build::Hopen::Base: common definitions for hopen.
# Thanks to David Farrell,
# https://www.perl.com/article/how-to-build-a-base-module/
# Copyright (c) 2018 Christopher White.  All rights reserved.
# LGPL 2.1+ - see the accompanying LICENSE file

package Build::Hopen::Base;
use parent 'Exporter';
use Import::Into;

our $VERSION = '0.000001';

# Pragmas
use 5.018;
use feature ":5.18";
use strict;
use warnings;

# Packages
use Data::Dumper;
use Carp;

# Definitions from this file
use constant {
    true => !!1,
    false => !!0,
};

our @EXPORT = qw(true false);
#our @EXPORT_OK = qw();
#our %EXPORT_TAGS = (
#    default => [@EXPORT],
#    all => [@EXPORT, @EXPORT_OK]
#);

#BEGIN {
#    $SIG{'__DIE__'} = sub { Carp::confess(@_) } unless $SIG{'__DIE__'};
#    #$Exporter::Verbose=1;
#}

sub import {
    my $target = caller;

    # Copy symbols listed in @EXPORT first, in case @_ gets trashed later.
    Build::Hopen::Base->export_to_level(1, @_);

    # Re-export pragmas
    feature->import::into($target, qw(:5.14));
    foreach my $pragma (qw(strict warnings)) {
        ${pragma}->import::into($target);
    };

    # Re-export packages
    Data::Dumper->import::into($target);
    Carp->import::into($target, qw(carp croak confess));

} #import()

1;
