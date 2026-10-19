*! tables.do — samples of the house table style.
*
* PERMANENT REFERENCE. Not on the Make graph, not part of the project's analysis.
* Builds one table of each kind economics papers use, from Stata's built-in `sysuse`
* datasets (no network, no data/derived dependency), and writes each as a .tex table into
* this folder's tracked output/tables/ — exactly the way the real analysis scripts
* export. Each table spells out the house esttab options inline (label, compress,
* nonotes, per-table number formats, \doublerule top + \midrule rules), so this file doubles as the
* copy-paste reference for how to call esttab with the house style for each table type.
* Tweak the options, rerun this, eyeball the fragments (or recompile
* code/reference/latex/styleguide.tex, which showcases them), repeat.
*
* This is the table companion to figures.do (graph schemes) in this folder.
*
* Table menu (program per table; toggle any off in `main`):
*   summary      descriptive stats: mean / sd / min / max / N        (estpost summarize)
*   correlation  pairwise correlation matrix                          (estpost correlate)
*   regression   nested OLS specs with stars, SEs, r2/N               (regress + eststo)
*   balance      two-group means, difference, significance            (estpost ttest)
*
* Run it (off the Makefile — invoke by hand, from anywhere in the repo):
*     stata-mp -b do code/reference/stata/tables.do
* or just double-click / `do` it from this folder.

clear all
set more off

* ==============================================================================
* main — build every table. Comment out a line to skip that table.
* ==============================================================================
capture program drop main
program define main
    init

    tab_summary
    tab_correlation
    tab_regression
    tab_balance

    display as text ">> tables.do complete"
end

* ==============================================================================
* init — bootstrap the project environment and set the output dir.
* ==============================================================================
capture program drop init
program define init
    * Find and run setup.do (repo root, adopath, dependencies), then plain-`do` it so
    * its output stays visible. setup.do climbs from cwd to the repo root, so we only
    * need to LOCATE it: probe the repo root (invoked via `make`/from root) and this
    * script's own folder (double-click / `do` from here).
    * See code/lib/stata/README.md for how the bootstrap works. setup.do adds
    * code/lib/stata to the adopath and cd's to the repo root.
    local setup "code/lib/stata/setup.do"          // cwd = repo root
    capture confirm file "`setup'"
    if _rc local setup "../../lib/stata/setup.do"   // cwd = code/reference/stata/
    capture confirm file "`setup'"
    if _rc {
        display as error "Could not find setup.do; cd to the repo root and rerun."
        exit 601
    }
    do "`setup'"

    * Output lands in this folder's own tracked output/ (artifacts colocated with the
    * code that made them). setup.do cd'd us to the repo root, so this relative path
    * resolves from there.
    global TAB_DIR "code/reference/stata/output/tables"
    cap mkdir "code/reference/stata/output"
    cap mkdir "${TAB_DIR}"
end

* ==============================================================================
* summary — descriptive statistics: mean / sd / min / max / N, one row per var.
* The most common opening table in an empirical paper. `estpost summarize` posts
* the stats so esttab can lay them out; `cells(...)` picks the columns and their
* format. label gives readable row names.
* ==============================================================================
capture program drop tab_summary
program define tab_summary
    preserve
    sysuse auto, clear
    label variable price  "Price"
    label variable mpg    "Mileage (mpg)"
    label variable weight "Weight (lbs)"
    label variable length "Length (in)"

    * clear any stored estimates so esttab uses THIS program's active result, not a
    * leftover from an earlier program (keeps each table self-contained / order-free).
    eststo clear
    estpost summarize price mpg weight length

    * House style, inline: label (readable row names), compress, nonotes (notes live in
    * the LaTeX caption). cells() sets its own per-stat formats here (summary stats aren't
    * estimates, so b()/se() don't apply). collabels sets the column headers;
    * nomtitle/nonumber drop the model row. `fragment` + our own prehead lets us open with
    * a flush \doublerule (see the LaTeX preamble); posthead is the \midrule under the
    * header, postfoot the closing \midrule (internal rules all \midrule for uniform width).
    esttab using "${TAB_DIR}/summary.tex", label compress nonotes replace fragment ///
        cells("mean(fmt(%9.2f)) sd(fmt(%9.2f)) min(fmt(%9.0f)) max(fmt(%9.0f)) count(fmt(%9.0f))") ///
        collabels("Mean" "SD" "Min" "Max" "N") ///
        nonumber nomtitle noobs ///
        prehead("\begin{tabular}{l*{5}{c}}" "\doublerule") ///
        posthead("\midrule") ///
        postfoot("\midrule" "\end{tabular}")
    display as text ">> wrote ${TAB_DIR}/summary.tex"
    restore
end

* ==============================================================================
* correlation — pairwise Pearson correlation matrix (lower triangle). The clean
* standalone analogue of code/analysis/price_rent_corr.do (which stacks three of
* these into era panels). not/nostar drop t-stats and stars; unstack lays the
* matrix out; nonumber/noobs strip the model header and observation row.
* ==============================================================================
capture program drop tab_correlation
program define tab_correlation
    preserve
    sysuse auto, clear
    label variable price  "Price"
    label variable mpg    "Mileage"
    label variable weight "Weight"
    label variable length "Length"

    eststo clear
    estpost correlate price mpg weight length, matrix listwise

    * House style, inline: label, compress, nonotes, b(%9.3f) (uniform 3-decimal cells).
    * not/nostar drop the t-stats and stars (esttab stars by default, so nostar is
    * required to keep a correlation matrix star-free). We build the tabular ourselves via
    * prehead/postfoot -- fragment + our own \begin{tabular}, \doublerule, and header row.
    * `booktabs` makes esttab's own header separator a \midrule (matching the rest); the
    * header-suppressing opts (nonumber/nomtitle/collabels(none)/eqlabels(none)) keep it
    * from emitting a second header. This is the standalone analogue of price_rent_corr.do.
    esttab using "${TAB_DIR}/correlation.tex", label compress nonotes b(%9.3f) replace ///
        fragment booktabs unstack not nostar noobs nonumber nomtitle ///
        collabels(none) eqlabels(none) ///
        prehead("\begin{tabular}{l*{4}{c}}" "\doublerule" "& Price & Mileage & Weight & Length \\") ///
        postfoot("\midrule" "\end{tabular}")
    display as text ">> wrote ${TAB_DIR}/correlation.tex"
    restore
end

* ==============================================================================
* regression — the workhorse econ table: several nested OLS specifications side by
* side, coefficients with significance stars, standard errors below in parentheses,
* and r2/N at the foot. `eststo` stores each model; the inline options supply the star
* convention, %9.3f coefficients, and SEs. keep() chooses which coefficients to
* show; se puts the SE under each estimate.
* ==============================================================================
capture program drop tab_regression
program define tab_regression
    preserve
    sysuse auto, clear
    label variable weight  "Weight (lbs)"
    label variable mpg     "Mileage (mpg)"
    label variable foreign "Foreign"

    eststo clear
    eststo: quietly regress price weight
    eststo: quietly regress price weight mpg
    eststo: quietly regress price weight mpg foreign

    * House style, inline: label, compress, nonotes, b(%9.3f) coefficients, se(%9.3f)
    * SEs, and the star convention. se -> SE under each coefficient; keep the three
    * regressors (drop the constant from the shown rows); r2 and N in the stats block.
    * Columns get esttab's automatic (1)(2)(3) number row; nomtitle drops the redundant
    * second header row of dependent-variable names (all "Price" here) so it stays one line.
    * `booktabs` makes esttab's OWN internal separators \midrule (the coefficients/stats
    * divider especially), so every rule matches; fragment + prehead open with \doublerule.
    esttab using "${TAB_DIR}/regression.tex", label compress nonotes replace fragment booktabs ///
        b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
        nomtitle keep(weight mpg foreign) ///
        stats(r2 N, fmt(%9.3f %9.0f) labels("R-squared" "Observations")) ///
        prehead("\begin{tabular}{l*{3}{c}}" "\doublerule") ///
        postfoot("\midrule" "\end{tabular}")
    display as text ">> wrote ${TAB_DIR}/regression.tex"
    restore
end

* ==============================================================================
* balance — two-group comparison: mean of each variable by group, the difference,
* and its significance. Common as a balance/summary-by-treatment table in applied
* micro and RCTs. `estpost ttest ... , by()` posts group means, the difference, and
* t-stats; esttab shows those columns with stars (from the p-values) on the difference.
* ==============================================================================
capture program drop tab_balance
program define tab_balance
    preserve
    sysuse auto, clear
    label variable price  "Price"
    label variable mpg    "Mileage (mpg)"
    label variable weight "Weight (lbs)"

    * clear stored estimates so esttab uses THIS program's ttest result, not a leftover
    * regression from tab_regression (keeps each table self-contained / order-free).
    eststo clear
    estpost ttest price mpg weight, by(foreign)

    * House style, inline: label, compress, nonotes, plus the star convention (the
    * b(star) cell needs star() thresholds). Domestic mean, Foreign mean, their difference
    * (starred), and the t-stat -- one row per variable. fragment + prehead open with a
    * flush \doublerule; posthead is the \midrule under the header, postfoot the closing one.
    esttab using "${TAB_DIR}/balance.tex", label compress nonotes replace fragment ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        cells("mu_1(fmt(%9.1f)) mu_2(fmt(%9.1f)) b(star fmt(%9.1f)) t(fmt(%9.2f) par)") ///
        collabels("Domestic" "Foreign" "Diff." "t") ///
        nonumber nomtitle noobs ///
        prehead("\begin{tabular}{l*{4}{c}}" "\doublerule") ///
        posthead("\midrule") ///
        postfoot("\midrule" "\end{tabular}")
    display as text ">> wrote ${TAB_DIR}/balance.tex"
    restore
end

main
