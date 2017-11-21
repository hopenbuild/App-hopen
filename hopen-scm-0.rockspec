package = "hopen"
version = "scm-0"
source = {
    url = "git+https://github.com/cxw42/hopen.git"
}
description = {
    summary = "A lightweight build system, similar in spirit to CMake",
    --detailed = "",
    homepage = "https://github.com/cxw42/hopen",
    license = "LGPL 3.0, or any later version, at your option.",
}
dependencies = {
    "lua ~> 5.2",
    "penlight >= 1.5.2",
    "luagraphs >= 1.0-5",
    "checks >= 1.0-1"
}
build = {
    type = "builtin",
    modules = {
        ["hopen.core"] = "src/hopen/core.lua",
        ["hopen.runner"] = "src/hopen/runner.lua",
    },

    copy_directories = { 'doc' },

    install = {
        bin = {
            hopen = 'bin/hopen'
        }
    }

}
