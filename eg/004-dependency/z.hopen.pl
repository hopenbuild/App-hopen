# A test of a dependency: libva
# On Ubuntu, this is package libva-dev.  I picked this one arbitrarily
# because it was one I could uninstall and reinstall during testing.

use language 'C';

rule->H::want(library => 'va')->
H::files('hello.c')->C::compile->C::link('hello')->default_goal;
