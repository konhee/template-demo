*! price_rent_timeseries.do — price-to-rent index over time, by rent series & window.
*
* The `analysis` stage: reads data/derived/build/price_rent_annual.csv and plots the
* (normalized) price-to-rent index as a time series, one line per call. Outputs go
* to output/figures/price_rent_timeseries/ — a subdir named for this script, so the
* code->output link is clear. Reads from data/derived/build/, writes only to output/.
*
* Run from the repo root (the Makefile does this):
*     stata-mp -b do code/analysis/price_rent_timeseries.do

clear all
set more off

* ==============================================================================
* main
* ==============================================================================
capture program drop main
program define main
    init

    prts rent_primary 2000 2024
    prts oer          2000 2024
    prts rent_primary 2005 2012

    display as text ">> price_rent_timeseries.do complete"
end

* ==============================================================================
* init — load the project environment and set shared paths.
* ==============================================================================
capture program drop init
program define init
    * Find and run setup.do (repo root, adopath, dependencies), then plain-`do` it
    * so its output stays visible. Stata's working dir depends on how it was
    * launched, so we try all three possible paths (labeled below) and use the
    * first that exists. See code/lib/stata/README.md.
    local setup "code/lib/stata/setup.do"             // cwd = repo root (make)
    capture confirm file "`setup'"
    if _rc local setup "../lib/stata/setup.do"        // cwd = code/<stage>/ (double-click)
    capture confirm file "`setup'"
    if _rc local setup "../../code/lib/stata/setup.do" // cwd = .make/logs/ (make batch logs)
    capture confirm file "`setup'"
    if _rc {
        display as error "Could not find setup.do; cd to the repo root and rerun."
        exit 601
    }
    do "`setup'"

    * Standard pipeline dirs (globals so prts sees them). Relative to root,
    * guaranteed by setup.do above. Names match the Python scripts' constants.
    * DERIVED_DIR points at the build producer namespace (this script consumes it);
    * FIG_DIR is a per-script subdir so outputs mirror the code that made them.
    global DERIVED_DIR "data/derived/build"
    global FIG_DIR     "output/figures/price_rent_timeseries"
    cap mkdir "output/figures"
    cap mkdir "${FIG_DIR}"
end

* ==============================================================================
* prts  rentseries  startyear  endyear — draw & export one time-series figure.
* ==============================================================================
capture program drop prts
program define prts
    args rentseries startyear endyear

    * fresh load each call so repeated calls don't accumulate state
    preserve
    local derived_file "${DERIVED_DIR}/price_rent_annual.csv"
    import delimited "`derived_file'", clear varnames(1)

    * MONO scheme, set explicitly: `set scheme` is session-scoped, so a prior
    * s2color (from price_rent_scatter.do) would otherwise carry over.
    set scheme s1mono

    * price-to-rent ratio for the chosen rent series
    gen double pr = zhvi / `rentseries'

    * normalize to 100 in the start year
    summarize pr if year == `startyear', meanonly
    if r(N) == 0 {
        display as error "prts: no data for startyear `startyear'"
        restore
        exit 198
    }
    local base = r(mean)
    replace pr = 100 * pr / `base'

    * restrict to the requested window
    keep if inrange(year, `startyear', `endyear')

    * Line styling comes from the scheme. aspectratio(0.667) pins the plot box to a
    * ~3:2 landscape shape, independent of the label/title slots.
    twoway (line pr year, sort), ///
        ytitle("") xtitle("Year") ///
        title("Price-to-Rent Index (`startyear' = 100)") ///
        aspectratio(0.667)

    * name outputs by the arguments so different calls don't overwrite. The folder
    * (FIG_DIR = .../price_rent_timeseries/) already carries the script name, so the
    * filename only needs the distinguishing series/window.
    local stub "${FIG_DIR}/`rentseries'_`startyear'_`endyear'"
    graph export "`stub'.pdf", replace
    graph export "`stub'.png", replace width(1600)
    display as text ">> wrote `stub'.pdf / .png"

    restore
end

main
