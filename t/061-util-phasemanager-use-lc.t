#!perl
# /home/cxw/proj/App-hopen/t/061-util-phasemanager-use-lc.t - test
#   App::hopen::Util::PhaseManager, but using lc instead of fc on newer Perls

BEGIN { $App::hopen::Util::PhaseManager::USE_LC = 1; }

use FindBin qw($Bin);
do "$Bin/060-util-phasemanager.t";
