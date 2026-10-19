*! setup.do — put cwd at the repo root, then wire up the Stata environment.
* Climbs from cwd to the nearest ancestor holding a root sentinel, adds this
* directory to the ado path, and loads dependencies. See README.md for the full
* rationale (why a climb, why these sentinels, the launch-mode table).

* Root markers, in priority order: config.mk pins *this* project (beats an outer
* git boundary for nested repos); .git/HEAD is the fallback for a bare checkout.
local sentinels "config.mk" ".git/HEAD"
local origin "`c(pwd)'"

* proj_root — the canonical project root (same concept as PROJ_ROOT in the
* Python scripts). Empty until a sentinel is found on the climb.
local proj_root ""
local prev  ""
while "`proj_root'" == "" & "`c(pwd)'" != "`prev'" {
    foreach s of local sentinels {
        capture confirm file "`s'"
        if _rc == 0 & "`proj_root'" == "" local proj_root "`c(pwd)'"
    }
    if "`proj_root'" == "" {
        local prev "`c(pwd)'"
        qui cd ..
    }
}
if "`proj_root'" == "" {
    qui cd "`origin'"
    display as error "setup.do: no repo root (`sentinels') above `origin'; cd to the project first."
    exit 601
}
qui cd "`proj_root'"

* Vendored .ado files here are now found by name. Absolute path so it survives
* any later `cd`.
adopath ++ "`proj_root'/code/lib/stata"

* Tier-2 dependencies (guarded so setup.do works before the file exists).
capture confirm file "code/lib/stata/dependencies.do"
if _rc == 0 do "code/lib/stata/dependencies.do"

display as text ">> setup.do: root = `proj_root'"
