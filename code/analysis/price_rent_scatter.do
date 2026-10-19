*! price_rent_scatter.do — ZHVI vs rent scatter, colored by GFC era (color-scheme demo).
*
* The `analysis` stage: reads data/derived/build/price_rent_annual.csv and plots ZHVI
* against Rent of Primary Residence, one marker per year, colored by GFC era
* (pre / GFC / post). Its main job is to DEMO and fine-tune the color house scheme
* (s2color) -- three groups exercise the p1/p2/p3 palette, the legend,
* and marker styling. Reads from data/derived/build/, writes only to output/.
*
* Run from the repo root (the Makefile does this):
*     stata-mp -b do code/analysis/price_rent_scatter.do

clear all
set more off

* ==============================================================================
* main
* ==============================================================================
capture program drop main
program define main
    init
    prsc
    display as text ">> price_rent_scatter.do complete"
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

    * Standard pipeline dirs (globals so prsc sees them). Relative to root,
    * guaranteed by setup.do above. FIG_DIR is a per-script subdir so outputs
    * mirror the code that made them.
    global DERIVED_DIR "data/derived/build"
    global FIG_DIR     "output/figures/price_rent_scatter"
    cap mkdir "output/figures"
    cap mkdir "${FIG_DIR}"
end

* ==============================================================================
* prsc — draw & export the ZHVI-vs-rent scatter, colored by GFC era.
* ==============================================================================
capture program drop prsc
program define prsc
    preserve
    import delimited "${DERIVED_DIR}/price_rent_annual.csv", clear varnames(1)

    * GFC era split (matches price_rent_corr.do): 1 pre-GFC, 2 GFC, 3 post-GFC.
    gen byte era = cond(year <= 2006, 1, cond(year <= 2013, 2, 3))

    * ZHVI is in dollars; scale to $000s so the axis labels stay short.
    gen double zhvi_k = zhvi / 1000

    * COLOR scheme, set explicitly (setup.do no longer pins a default). One scatter
    * call per era so each group draws in its own palette color (p1/p2/p3).
    set scheme s2color

    * aspectratio(0.667) pins the plot box to a ~3:2 landscape shape. The x-title
    * stays: a scatter's x-axis isn't self-evident the way a year axis is.
    twoway (scatter zhvi_k rent_primary if era == 1) ///
           (scatter zhvi_k rent_primary if era == 2) ///
           (scatter zhvi_k rent_primary if era == 3), ///
        ytitle("") xtitle("Rent of primary residence (CPI)") ///
        title("ZHVI ($000s)") ///
        legend(order(1 "Pre-GFC" 2 "GFC" 3 "Post-GFC") position(5)) ///
        aspectratio(0.667)

    local stub "${FIG_DIR}/zhvi_vs_rent_by_era"
    graph export "`stub'.pdf", replace
    graph export "`stub'.png", replace width(1600)
    display as text ">> wrote `stub'.pdf / .png"

    restore
end

main
