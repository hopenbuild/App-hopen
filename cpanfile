# Auto-generated from Makefile.PL by cpanfile-from-Makefile-PL
requires 'Carp';
requires 'Class::Method::Modifiers', '2.10';
requires 'Class::Tiny', '1.000';
requires 'Class::Tiny::ConstrainedAccessor', '0.000010';
requires 'Config';
requires 'Cwd';
requires 'Data::Dumper', '2.154';
requires 'Data::Hopen', '0.000020';
requires 'Data::Section::Simple', '0.07';
requires 'Deep::Hash::Utils', '0.03';
requires 'Exporter';
requires 'File::Glob';
requires 'File::Path::Tiny', '0.9';
requires 'File::Spec';
requires 'File::Which', '1.22';
requires 'File::pushd', '1.013';
requires 'File::stat';
requires 'Getargs::Mixed', '1.04';
requires 'Getopt::Long', '2.5';
requires 'Graph', '0.9704';
requires 'Hash::Merge', '0.299';
requires 'Hash::MultiValue', '0.12';
requires 'Import::Into';
requires 'List::Flatten::Recursive', '0.210100';
requires 'List::MoreUtils', '0.428';
requires 'Package::Alias', '0.12';
requires 'Path::Class', '0.37';
requires 'PerlX::Maybe', '1.200';
requires 'Pod::Usage';
requires 'Quote::Code', '1.01';
requires 'Scalar::Util';
requires 'Set::Scalar', '1.27';
requires 'String::Print', '0.92';
requires 'Text::MicroTemplate', '0.23';
requires 'Tie::RefHash';
requires 'Type::Tiny', '1.004004';
requires 'XML::FromPerl';
requires 'XML::LibXML', '1.60';
requires 'constant';
requires 'feature';
requires 'overload';
requires 'perl', '5.014';
requires 'strict';
requires 'vars::i', '1.06';
requires 'warnings';

on configure => sub {
    requires 'Config';
    requires 'ExtUtils::MakeMaker';
    requires 'File::Spec';
    requires 'strict';
    requires 'warnings';
};

on build => sub {
    requires 'Getopt::Long';
    requires 'Path::Class', '0.37';
    requires 'Pod::Markdown';
    requires 'Pod::Text';
    recommends 'Pod::ProjectDocs', '0.52';
};

on test => sub {
    requires 'Carp';
    requires 'Exporter';
    requires 'Import::Into';
    requires 'Scalar::Util';
    requires 'Test::Deep', '0.084';
    requires 'Test::Directory', '0.02';
    requires 'Test::Fatal', '0.014';
    requires 'Test::More';
    requires 'Test::UseAllModules', '0.12';
    requires 'Test::Warn', '0.35';
    requires 'rlib';
};

on develop => sub {
    requires 'App::RewriteVersion';
    requires 'CPAN::Meta';
    requires 'Devel::Cover';
    requires 'File::Slurp', '9999.26';
    requires 'Module::CPANfile', '0.9020';
    requires 'Module::Metadata', '1.000016';
    requires 'Test::Kwalitee';
};
