#!perl
# t/211-util-templates-fnname.t - tests of App::hopen::Util::Templates, using
# a custom function name
use rlib 'lib';
use HopenTest;
use Test::Fatal;
use Path::Class;

use App::hopen::Util::Templates qw(magick);

is(ref magick('answer'), 'CODE', 'Existent template returns coderef');
like(exception { magick('NONEXISTENT') }, qr/No template NONEXISTENT/,
    'Nonexistent template throws');
like(exception { magick('invalid') }, qr/Could not create template invalid/,
    'Invalid template throws');
is(magick('answer')->(), "42\n", 'No-param template');
is(magick('param')->(arg => 1337), "1337\n", 'One-param template, hash');
is(magick('param')->({arg => 1337}), "1337\n", 'One-param template, hashref');

done_testing();

__DATA__
@@ answer
42

@@ param
?= $v{arg}

@@ invalid
?= $no_such_variable
