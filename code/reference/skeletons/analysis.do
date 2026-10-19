*! analysis.do — SKELETON for a Stata analysis/build script. Copy this to start.
*
* PERMANENT REFERENCE, not on the Make graph. The shape every pipeline .do follows:
* `main` calls `init` then one worker program per output. Runs as-is on `sysuse auto`
* (no data/ needed) -- run it once to see the pattern, then point it at your data.
*   - main   = table of contents: init, then the worker calls.
*   - init   = bootstrap (find + run setup.do), set the output dir.
*   - worker = one program per artifact; loads its own data with `, clear`, names its
*              output from its args.
*
* Run it (off the Makefile — from anywhere in the repo):
*     stata-mp -b do code/reference/skeletons/analysis.do

clear all
set more off

* ==============================================================================
* main — init first, then one call per output.
* ==============================================================================
capture program drop main
program define main
    init

    make_figure mpg      // one call = one artifact; the arg names the output
    make_figure weight

    display as text ">> analysis.do complete"
end

* ==============================================================================
* init — bootstrap the environment and set the output dir. Copy verbatim into a
* real script; only FIG_DIR (and any input dirs) change.
* ==============================================================================
capture program drop init
program define init
    * Find and run setup.do (repo root, adopath, dependencies). Stata's working dir
    * depends on how it was launched, so try the three possible paths and use the
    * first that exists. See code/lib/stata/README.md.
    *
    * The middle probe is "../../lib/..." because this skeleton sits two levels below
    * root; a real script in code/analysis/ is one level below, so it uses "../lib/...".
    * Match the climb to wherever you copy this.
    local setup "code/lib/stata/setup.do"                 // cwd = repo root (make)
    capture confirm file "`setup'"
    if _rc local setup "../../lib/stata/setup.do"          // cwd = code/reference/skeletons/
    capture confirm file "`setup'"
    if _rc local setup "../../code/lib/stata/setup.do"     // cwd = .make/logs/ (make batch logs)
    capture confirm file "`setup'"
    if _rc {
        display as error "Could not find setup.do; cd to the repo root and rerun."
        exit 601
    }
    do "`setup'"

    * Output subdir named for this script (the code->output link). setup.do cd'd us
    * to the repo root, so this resolves from there. A real script also sets an input
    * dir here, pointing at the producer namespace it reads (e.g. DERIVED_DIR
    * "data/derived/build").
    global FIG_DIR "code/reference/skeletons/output"
    cap mkdir "${FIG_DIR}"
end

* ==============================================================================
* make_figure  var — draw & export one figure for the chosen variable.
* ==============================================================================
capture program drop make_figure
program define make_figure
    args var

    * Load fresh with `, clear` (a real script imports from ${DERIVED_DIR} here).
    sysuse auto, clear

    * House layout (see code/reference/stata/figures.do for the full menu): y-label as
    * the title at clock-11, blank ytitle, aspectratio pins a ~3:2 box. Scheme styling
    * comes from setup.do.
    twoway (scatter `var' price), ///
        ytitle("") xtitle("Price ($)") ///
        title("`var'") ///
        aspectratio(0.667)

    * Name the output by the arg so calls don't overwrite (the folder already carries
    * the script name).
    local stub "${FIG_DIR}/`var'"
    graph export "`stub'.pdf", replace
    graph export "`stub'.png", replace width(1600)
    display as text ">> wrote `stub'.pdf / .png"
end

main
