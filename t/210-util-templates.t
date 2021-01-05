#!perl
# t/210-util-templates.t - tests of App::hopen::Util::Templates
use rlib 'lib';
use HopenTest;
use Test::Fatal;
use Path::Class;

use App::hopen::Util::Templates;

is(ref template('answer'), 'CODE', 'Existent template returns coderef');
like(exception { template('NONEXISTENT') }, qr/No template NONEXISTENT/,
    'Nonexistent template throws');
like(exception { template('invalid') }, qr/Could not create template invalid/,
    'Invalid template throws');
is(template('answer')->(), "42\n", 'No-param template');
is(template('param')->(arg => 1337), "1337\n", 'One-param template, hash');
is(template('param')->({arg => 1337}), "1337\n", 'One-param template, hashref');

done_testing();

__DATA__
@@ answer
42

@@ param
?= $v{arg}

@@ invalid
?= $no_such_variable
