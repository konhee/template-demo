*! step02_plot_transition.do — PLOT step of the model stage (model diagnostic).
*
* The `model` stage, step 2: read the model solution written by step01_solve.m and
* draw a paper-facing figure of the transition path. This is a MODEL diagnostic — it
* lives in code/model/ (not code/analysis/) because plotting a model's own solution
* belongs to the model stage; there is no analysis <- model back-edge to manage.
*
* It also shows the house division of labour: the solve is MATLAB, the plot is Stata
* (Stata's default scheme via setup.do), so the two languages coexist within one stage.
* Prefixed step02_ so the sorted `find` runs it AFTER step01_solve.m (the .csv must
* exist). "step" is a word, not a bare digit, so the same scheme is legal for MATLAB
* (which cannot run an m-file whose name starts with a digit).
*
* Reads  data/derived/model/solow_transition.csv  (produced by step01_solve.m)
* Writes output/figures/solow_transition/{capital,consumption}.pdf/.png
*
* Run it (as part of the stage): make model
*     (or standalone: stata-mp -b do code/model/step02_plot_transition.do, after step01)

clear all
set more off

* ==============================================================================
* main — init first, then one call per artifact.
* ==============================================================================
capture program drop main
program define main
    init

    make_path capital     k  "Capital per effective worker"
    make_path consumption c  "Consumption per effective worker"

    display as text ">> step02_plot_transition.do complete"
end

* ==============================================================================
* init — bootstrap the environment and set input/output dirs.
* ==============================================================================
capture program drop init
program define init
    * Find and run setup.do (repo root, adopath, dependencies, default scheme). Try
    * the three possible working dirs and use the first that exists (see
    * code/lib/stata/README.md). The middle probe is "../lib/..." because a script in
    * code/model/ sits one level below the repo root.
    local setup "code/lib/stata/setup.do"              // cwd = repo root (make)
    capture confirm file "`setup'"
    if _rc local setup "../lib/stata/setup.do"          // cwd = code/model/ (double-click)
    capture confirm file "`setup'"
    if _rc local setup "../../code/lib/stata/setup.do"  // cwd = .make/logs/ (make batch logs)
    capture confirm file "`setup'"
    if _rc {
        display as error "Could not find setup.do; cd to the repo root and rerun."
        exit 601
    }
    do "`setup'"

    * DERIVED_DIR points at the MODEL producer namespace: this diagnostic consumes
    * the model's own output. FIG_DIR is a per-script subdir so outputs mirror the
    * code that made them. Both resolve from the repo root (setup.do cd'd us there).
    global DERIVED_DIR "data/derived/model"
    global FIG_DIR     "output/figures/solow_transition"
    cap mkdir "output/figures"
    cap mkdir "${FIG_DIR}"
end

* ==============================================================================
* make_path  var  yvar  title — plot one transition series against time.
* ==============================================================================
capture program drop make_path
program define make_path
    args var yvar title

    * fresh load each call so repeated calls don't accumulate state
    preserve
    local infile "${DERIVED_DIR}/solow_transition.csv"
    capture confirm file "`infile'"
    if _rc {
        display as error "make_path: `infile' not found — run step01_solve.m first (make model)."
        restore
        exit 601
    }
    import delimited "`infile'", clear varnames(1)

    * House layout (see code/reference/stata/figures.do): y-label as the title,
    * blank ytitle, aspectratio pins a ~3:2 box. Scheme styling comes from setup.do.
    twoway (line `yvar' t, sort), ///
        ytitle("") xtitle("Period") ///
        title("`title'") ///
        aspectratio(0.667)

    local stub "${FIG_DIR}/`var'"
    graph export "`stub'.pdf", replace
    graph export "`stub'.png", replace width(1600)
    display as text ">> wrote `stub'.pdf / .png"

    restore
end

main
