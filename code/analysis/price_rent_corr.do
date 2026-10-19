*! price_rent_corr.do — correlations of price & rent levels, by GFC era.
*
* The `analysis` stage: reads data/derived/build/price_rent_annual.csv and writes a
* three-panel correlation table (ZHVI, Rent of Primary Residence, OER, in
* levels) to output/tables/. One panel per era: pre-GFC, GFC, post-GFC.
* Reads from the build producer namespace data/derived/build/, writes only to output/.
*
* Run from the repo root (the Makefile does this):
*     stata-mp -b do code/analysis/price_rent_corr.do

clear all
set more off

* ==============================================================================
* main
* ==============================================================================
capture program drop main
program define main
    init

    * fresh load; label the variables so esttab picks up readable row/col names
    import delimited "${DERIVED_DIR}/price_rent_annual.csv", clear varnames(1)
    label variable zhvi         "ZHVI"
    label variable rent_primary "Rent"
    label variable oer          "OER"

    * one file, three stacked panels (first opens the tabular, last closes it)
    local out "${TAB_DIR}/price_rent_corr.tex"
    corrpanel "Pre-GFC (2000--2006)"   2000 2006 first `out'
    corrpanel "GFC (2007--2013)"       2007 2013 mid   `out'
    corrpanel "Post-GFC (2014--2024)"  2014 2024 last  `out'
    display as text ">> wrote `out'"

    display as text ">> price_rent_corr.do complete"
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

    * Standard pipeline dirs (globals so corrpanel sees them). Relative to root,
    * guaranteed by setup.do above. Names match the Python scripts' constants.
    * DERIVED_DIR points at the build producer namespace (this script consumes it).
    global DERIVED_DIR "data/derived/build"
    global TAB_DIR     "output/tables"
    cap mkdir "${TAB_DIR}"
end

* ==============================================================================
* corrpanel  label  startyear  endyear  position  filepath — one era's panel.
*   position: first | mid | last  (first opens the tabular, last closes it, so
*   the three calls together emit a single stacked table.)
* ==============================================================================
capture program drop corrpanel
program define corrpanel
    args label startyear endyear position filepath

    preserve
    keep if inrange(year, `startyear', `endyear')
    estpost correlate zhvi rent_primary oer, matrix listwise

    * The tabular header/footer live on the first/last panels only; every panel
    * contributes a titled block of correlations in between. Rules: a \doublerule at
    * the top, a \midrule between panels, and a \midrule at the bottom. \doublerule and
    * the rule spacing are defined in the LaTeX preamble; here we just emit the commands.
    local prehead
    local postfoot
    local writemode append
    if "`position'" == "first" {
        local writemode replace
        local prehead prehead("\begin{tabular}{l*{3}{c}}" "\doublerule" "& ZHVI & Rent & OER \\")
    }
    if "`position'" == "last" {
        local postfoot postfoot("\midrule" "\end{tabular}")
    }

    * House style, inline: label (readable names), compress, b(%9.3f) (3-decimal
    * cells that line up under centered columns without siunitx), nonotes (notes go
    * in the LaTeX caption). `fragment` because the three panels share ONE tabular we
    * open/close ourselves via prehead/postfoot. `not nostar` drop t-stats/stars (a
    * correlation matrix has neither); unstack + eqlabels/collabels(none) + nonumbers
    * + noobs shape the matrix layout. posthead opens each panel with a \midrule
    * divider and the era label.
    esttab using "`filepath'", label compress nonotes b(%9.3f) `writemode' fragment ///
        unstack collabels(none) eqlabels(none) nonumbers nomtitles noobs not nostar ///
        `prehead' ///
        posthead("\midrule \multicolumn{4}{l}{\textit{`label'}} \\[0.3em]") ///
        `postfoot'

    restore
end

main
