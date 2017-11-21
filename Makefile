# hopen makefile

default: local

local:
	luarocks make --local --deps-mode=all
	# deps-mode: https://github.com/luarocks/luarocks/wiki/dependencies#dependency-modes

test:
	busted spec

run:
	lua -l here -- bin/hopen

