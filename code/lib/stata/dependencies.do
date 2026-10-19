*! dependencies.do — ensure required third-party Stata packages are available.
*
* TIER 2 of the project's dependency strategy (see code/lib/stata/README below,
* and setup.do). This file handles packages we do NOT author and pull from SSC /
* net: install once, then skip if already present.
*
* Sourced automatically by setup.do once the repo root is known, so `which`
* checks and any install run with the working directory at the root.
*
* HOW IT DEGRADES
*   - Package already installed (or vendored into code/lib/stata and thus on the
*     adopath): `which` succeeds, we skip it. No network needed.
*   - Package missing + machine online with write access: we `ssc install` it.
*   - Package missing + offline / locked-down (e.g. a corporate/institutional Windows machine, no admin): the
*     install fails loudly with guidance to VENDOR it (Tier 1) instead — copy the
*     package's .ado/.sthlp into code/lib/stata and commit them, so it travels
*     with the repo and never needs the network again.
*
* MAINTAINING THE LIST
*   Add package names to `required` as the project grows. Names must match what
*   `which <name>` looks for (usually the command name). Packages that live on
*   SSC install with `ssc install`; anything only on a net URL needs its own
*   `net install ..., from(...)` line — add those as explicit exceptions below.

* ------------------------------------------------------------------------------
* SSC packages (install via `ssc install <pkg>`). gtools is here both in its own
* right and because binscatter2 (below) depends on it.
* ------------------------------------------------------------------------------
local required "binscatter reghdfe gtools estout"

foreach pkg of local required {
    capture which `pkg'
    if _rc {
        display as text ">> dependencies.do: installing `pkg' from SSC ..."
        capture noisily ssc install `pkg', replace
        if _rc {
            display as error ///
"{p}dependencies.do: could not install `pkg' (offline or locked-down machine?). "
            display as error ///
"Vendor it instead: copy its .ado/.sthlp files into code/lib/stata and commit them.{p_end}"
        }
    }
}

* ------------------------------------------------------------------------------
* net-only packages (not on SSC) — same guarded pattern, but installed from an
* explicit URL. binscatter2 lives on GitHub and requires gtools (above).
* ------------------------------------------------------------------------------
capture which binscatter2
if _rc {
    display as text ">> dependencies.do: installing binscatter2 from GitHub ..."
    capture noisily net install binscatter2, replace ///
        from("https://raw.githubusercontent.com/mdroste/stata-binscatter2/master/")
    if _rc {
        display as error ///
"{p}dependencies.do: could not install binscatter2 (offline or locked-down machine?). "
        display as error ///
"Vendor it instead: copy its .ado/.sthlp files into code/lib/stata and commit them.{p_end}"
    }
}

display as text ">> dependencies.do: dependency check complete."
