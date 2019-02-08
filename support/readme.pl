#!perl
# readme_md.pl: Make README.md from a Perl file.
# Part of Build::Hopen.

use Getopt::Long qw(:config gnu_getopt);
use Path::Class;

# Parse command-line options
my ($source_fn, $dest_fn);
my $format = 'md';
GetOptions( "i|input=s" => \$source_fn,
            "o|output=s" => \$dest_fn,
            "f|format=s" => \$format)
    or die "Error in arguments.  Usage:\nreadme_md.pl -i input -o output [-f format]\nFormat = md (default) or text.";

die "Need an input file" unless $source_fn;
die "Need an output file" unless $dest_fn;

# Load the right parser
my $parser;
if($format eq 'md') {
    require Pod::Markdown;
    $parser = Pod::Markdown->new;

} elsif($format eq 'text') {
    require Pod::Text;
    $parser = Pod::Text->new(sentence => 1, width => 78);

} else {
    die "Invalid format $format (I understand 'md' and 'text')"
}

# Turn the POD into the output format
my $parsed = '';
$parser->output_string(\$parsed);
my $pod = file($source_fn)->slurp;
$parser->parse_string_document($pod);
open my $fh, '<', \$parsed;

# Filter and tweak the POD
my $saw_name = 0;
my $tweak_name = ($format eq 'md');
my $force_conventions = ($format eq 'md');

while(my $line = <$fh>) {

    # In Markdown, turn NAME into the text, as a heading.
    # Also add the Appveyor badge.
    if($tweak_name && !$saw_name && $line =~ /NAME/) {
        $saw_name = 1;
        next;
    } elsif($tweak_name && $saw_name && $line =~ m{\H\h*$/}) {
        $output .= ($format eq 'md' ? '# ' : '') . "$line\n";
        $output .= "[![Appveyor Badge](https://ci.appveyor.com/api/projects/status/github/cxw42/hopen?svg=true)](https://ci.appveyor.com/project/cxw42/hopen)\n\n";
        $saw_name = 0;
        next;
    } elsif($tweak_name && $saw_name) {
        next;   # Waiting for the name line to come around
    }

    next if $line =~ /SYNOPSIS/;    # Don't need this header.

    # Skip the internals
    $output .= $line if $line =~ /SUPPORT/;
    next if ($line =~ /VARIABLES/)..($line =~ /SUPPORT/);

    $line =~ s{https://metacpan.org/pod/Build::Hopen::Conventions}{https://metacpan.org/pod/release/CXW/Build-Hopen-0.000006-TRIAL/lib/Build/Hopen/Conventions.pod} if $force_conventions;

    $output .= $line;   # Copy everything that's left.
}

file($dest_fn)->spew($output);
