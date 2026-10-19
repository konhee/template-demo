*! figures.do — visual samples of common chart types, in Stata.
*
* PERMANENT REFERENCE. Not on the Make graph, not part of the project's analysis.
* Draws one figure of each chart type economics papers use under BOTH a mono and a
* color scheme (s1mono, s2color), from Stata's built-in `sysuse` datasets (no network,
* no data/derived dependency), and exports them exactly the way the real analysis
* scripts do (PDF + 1600px PNG, house export stub). Swap in your own scheme in
* code/lib/stata/ if you want a custom look, rerun this, eyeball output/mono/ and output/color/, repeat.
*
* One looped source, two schemes: `main` runs the SAME chart menu once per scheme,
* writing s1mono to output/mono/ and s2color to output/color/ so the two
* can be compared side by side. There is no second script to keep in sync -- change
* a chart here and both schemes pick it up.
*
* Chart menu (program per chart; toggle any off in `draw_all`):
*   scatter      one group, structural marker
*   timeseries   single line, top-left y-label, symmetric x ticks
*   histogram    single distribution
*   eventstudy   coefficients +/- 95% CI around an event, ref period t=-1 pinned to 0
*   coefplot     coefficients across specs, horizontal, CI whiskers
*   bar          mean per category, single series (twoway bar)
*   binscatter        binned means by group
*   kdensity          overlaid densities by group
*   histogram_overlap kdensity + translucent histogram fill, overlaid by group
*
* Run it (off the Makefile — invoke by hand, from anywhere in the repo):
*     stata-mp -b do code/reference/stata/figures.do
* or just double-click / `do` it from this folder.

clear all
set more off

* ------------------------------------------------------------------------------
* CONFIG — the schemes to render and the filename suffix each gets.
* Add a scheme by extending this list ("<scheme> <suffix>" pairs).
* ------------------------------------------------------------------------------
global SCHEMES "s1mono mono s2color color"

* ==============================================================================
* main — bootstrap once, then run the full chart menu per scheme in ${SCHEMES}.
* ==============================================================================
capture program drop main
program define main
    init

    * Walk ${SCHEMES} two tokens at a time: scheme name, then its filename suffix.
    local toks "${SCHEMES}"
    while "`toks'" != "" {
        gettoken scheme toks : toks
        gettoken suffix toks : toks
        use_scheme "`scheme'" "`suffix'"
        draw_all
        display as text ">> figures.do: `scheme' -> output/figures/*_`suffix'.pdf complete"
    }

    display as text ">> figures.do complete"
end

* ==============================================================================
* init — bootstrap the project environment (repo root, adopath, dependencies) and
* set the output dir. Both schemes write here; the scheme is a filename suffix, so
* one flat output/figures/ mirrors the top-level output/figures/ convention.
* ==============================================================================
capture program drop init
program define init
    * Find and run setup.do (repo root, adopath, dependencies), then plain-`do` it
    * so its output stays visible. setup.do itself climbs from cwd to the repo root,
    * so we only need to LOCATE it: probe the repo root (invoked via `make`/from root)
    * and this script's own folder (double-click / `do` from here). setup.do adds
    * code/lib/stata to the adopath (for the vendored house schemes) and cd's to root.
    * See code/lib/stata/README.md for how the bootstrap works.
    local setup "code/lib/stata/setup.do"          // cwd = repo root
    capture confirm file "`setup'"
    if _rc local setup "../../lib/stata/setup.do"   // cwd = code/reference/stata/
    capture confirm file "`setup'"
    if _rc {
        display as error "Could not find setup.do; cd to the repo root and rerun."
        exit 601
    }
    do "`setup'"

    * Output lands in this folder's own tracked output/figures/ (figures colocated
    * with the code that made them). setup.do cd'd us to the repo root, so this
    * relative path resolves from there.
    global FIG_DIR "code/reference/stata/output/figures"
    cap mkdir "code/reference/stata/output"
    cap mkdir "${FIG_DIR}"
end

* ==============================================================================
* use_scheme  scheme suffix — set the graph scheme and the filename suffix that
* tags every figure this pass writes (so mono and color runs never clobber).
* ==============================================================================
capture program drop use_scheme
program define use_scheme
    args scheme suffix
    set scheme `scheme'
    global SUFFIX "`suffix'"
end

* ==============================================================================
* draw_all — draw every chart under the currently-set scheme. Comment out a line
* to skip that chart. Called once per scheme.
* ==============================================================================
capture program drop draw_all
program define draw_all
    fig_scatter
    fig_timeseries
    fig_histogram
    fig_eventstudy
    fig_coefplot
    fig_bar
    fig_binscatter
    fig_kdensity
    fig_histogram_overlap
end

* ==============================================================================
* figexport  name — export the current graph the house way (PDF + wide PNG). The
* active scheme's suffix (mono/color) tags the filename, so both schemes' versions
* of a chart sort adjacent (scatter_color, scatter_mono). Mirrors the export block
* in the real analysis scripts, which likewise name outputs by a distinguisher.
* ==============================================================================
capture program drop figexport
program define figexport
    args name
    local stub "${FIG_DIR}/`name'_${SUFFIX}"
    graph export "`stub'.pdf", replace
    graph export "`stub'.png", replace width(1600)
    display as text ">> wrote `stub'.pdf / .png"
end

* ==============================================================================
* scatter (single group). Tests the marker: palette-color fill at p1 with a
* hairline structural outline.
* ==============================================================================
capture program drop fig_scatter
program define fig_scatter
    preserve
    sysuse auto, clear

    * House layout (see price_rent_scatter.do for the full rationale): y-label as a
    * left-justified title at clock-11, blank ytitle, x-title kept (a scatter's x is
    * not self-evident). Square box via aspectratio(1).
    twoway (scatter mpg weight), ///
        ytitle("") xtitle("Weight (lbs)") ///
        title("Mileage (mpg)") ///
        aspectratio(1)
    figexport "scatter"
    restore
end

* ==============================================================================
* time series (single line). Same house layout as price_rent_timeseries.do.
* ==============================================================================
capture program drop fig_timeseries
program define fig_timeseries
    preserve
    sysuse uslifeexp, clear

    * Symmetric x ticks with both endpoints on the data edges (xlabel 1900(20)2000).
    twoway (line le year, sort), ///
        ytitle("") xtitle("Year") ///
        title("Life expectancy (years)") ///
        xlabel(1900(20)2000) ///
        aspectratio(0.667)
    figexport "timeseries"
    restore
end

* ==============================================================================
* histogram (single distribution).
* ==============================================================================
capture program drop fig_histogram
program define fig_histogram
    preserve
    sysuse auto, clear

    * twoway histogram (a real twoway plot type) so the full house layout applies --
    * unlike the standalone `histogram` command, twoway-level options like aspectratio
    * actually take effect. Bars fill with the p1 color and the hairline outline.
    twoway (histogram mpg, percent), ///
        ytitle("") xtitle("Mileage (mpg)") ///
        title("Percent") ///
        aspectratio(0.667)
    figexport "histogram"
    restore
end

* ==============================================================================
* event study. Synthetic coefficients +/- 95% CI around an event at t=0,
* reference period t=-1 normalized to exactly 0. A staple DiD/event-study plot.
* ==============================================================================
capture program drop fig_eventstudy
program define fig_eventstudy
    preserve
    clear
    set obs 11
    gen int t = _n - 6                       // event time -5 .. 5

    * Flat, near-zero pre-trend; a jump that grows after the event.
    gen double coef = cond(t < 0, 0, 0.15 * (t + 1))
    replace coef = 0 if t == -1              // reference period, pinned to 0
    gen double se = cond(t == -1, 0, 0.05 + 0.01 * abs(t))
    gen double hi = coef + 1.96 * se
    gen double lo = coef - 1.96 * se

    * CI as a shaded band (rarea) under the point-and-line estimate. xline marks the
    * event, yline the zero effect. Both reference lines inherit the structural ink.
    twoway (rarea hi lo t) ///
           (connected coef t), ///
        ytitle("") xtitle("Event time") ///
        title("Coefficient (95% CI)") ///
        xlabel(-5(1)5) ///
        yline(0) xline(0) ///
        legend(off) ///
        aspectratio(0.667)
    figexport "eventstudy"
    restore
end

* ==============================================================================
* coefficient plot. Synthetic coefficients across four specifications, horizontal,
* with 95% CI whiskers.
* ==============================================================================
capture program drop fig_coefplot
program define fig_coefplot
    preserve
    clear
    set obs 4
    gen int spec = _n
    gen double coef = .30 + .05 * spec       // drifting point estimates
    gen double se   = .06
    gen double hi = coef + 1.96 * se
    gen double lo = coef - 1.96 * se
    label define specL 1 "Baseline" 2 "+ Controls" 3 "+ FE" 4 "+ Cluster"
    label values spec specL

    * Horizontal layout: spec on y, coefficient on x. rcap draws the CI as a
    * horizontal whisker; xline(0) is the null. ylabel spans all four spec rows.
    twoway (rcap hi lo spec, horizontal) ///
           (scatter spec coef), ///
        ytitle("") xtitle("Coefficient (95% CI)") ///
        title("Specification") ///
        ylabel(1(1)4, valuelabel) yscale(reverse) ///
        xline(0) ///
        legend(off) ///
        aspectratio(0.667)
    figexport "coefplot"
    restore
end

* ==============================================================================
* bar chart. Mean mpg by repair record. Built as twoway (not `graph bar`) so it
* shares the house twoway layout: collapse to one mean per category, then plot
* `twoway bar` of mean vs the numeric category.
* ==============================================================================
capture program drop fig_bar
program define fig_bar
    preserve
    sysuse auto, clear

    * `graph bar` is NOT twoway, so it can't take the twoway house layout (noline,
    * aspectratio, clock-11 title). `twoway bar` CAN -- but it needs y-vs-x data, so
    * collapse to one mean per group first (mirrors fig_binscatter's collapse). Single
    * series, so it uses house_fill (p1/a light grey), not a per-category palette.
    collapse (mean) mpg, by(rep78)
    drop if missing(rep78)

    * barwidth(0.8) leaves a small gap between bars; xlabel from the category values.
    twoway (bar mpg rep78, barwidth(0.8)), ///
        ytitle("") xtitle("Repair record (1977)") ///
        title("Mean mileage (mpg)") ///
        xlabel(1(1)5) ///
        aspectratio(0.667)
    figexport "bar"
    restore
end

* ==============================================================================
* binned scatter by group. Manual bin-and-collapse (no external package, so it
* stays self-contained): decile bins of weight within each group, mean of both
* axes per bin.
* ==============================================================================
capture program drop fig_binscatter
program define fig_binscatter
    preserve
    sysuse auto, clear

    replace weight = weight/1000

    local nbins 10
    gen int bin = .
    forvalues g = 0/1 {
        xtile b = weight if foreign == `g', nq(`nbins')
        replace bin = b if foreign == `g'
        drop b
    }
    collapse (mean) mpg weight, by(foreign bin)

    twoway (scatter mpg weight if foreign == 0) ///
           (scatter mpg weight if foreign == 1), ///
        ytitle("") xtitle("Weight (lbs, thousands)") ///
        title("Mileage (mpg)") ///
        legend(order(1 "Domestic" 2 "Foreign")) ///
        aspectratio(1)
    figexport "binscatter"
    restore
end

* ==============================================================================
* kernel-density overlay by group. Two densities on one axis; a good test of the
* line palette and the legend.
* ==============================================================================
capture program drop fig_kdensity
program define fig_kdensity
    preserve
    sysuse auto, clear

    twoway (kdensity mpg if foreign == 0) ///
           (kdensity mpg if foreign == 1), ///
        ytitle("") xtitle("Mileage (mpg)") ///
        title("Density") ///
        legend(order(1 "Domestic" 2 "Foreign")) ///
        aspectratio(0.667)
    figexport "kdensity"
    restore
end

* ==============================================================================
* histogram + kdensity overlay by group. Like fig_kdensity, but with the
* underlying histograms shown (translucent fill) behind each density line.
* ==============================================================================
capture program drop fig_histogram_overlap
program define fig_histogram_overlap
    preserve
    sysuse auto, clear

    * Asymmetric mono shading (one group unfilled, the other faintly filled) has no
    * generic scheme slot to lean on -- branch by hand, keyed on ${SUFFIX} (this
    * script's own mono/color tag, set in use_scheme) rather than c(scheme) (the
    * scheme's filename), so this doesn't break if a scheme is ever renamed.
    if "${SUFFIX}" == "color" {
        local facecolor1 red%20
        local facecolor2 navy%20
        local linecolor1 red
        local linecolor2 navy
    }
    else if "${SUFFIX}" == "mono" {
        local facecolor1 none
        local facecolor2 black%14
        local linecolor1 black
        local linecolor2 black%28
    }

    twoway (hist mpg if foreign == 0, width(2) fcolor(`facecolor1') lcolor(`linecolor1')) ///
        (kdensity mpg if foreign == 0, lcolor(`linecolor1') lpattern(solid) lwidth(medium)) ///
        (hist mpg if foreign == 1, width(2) fcolor(`facecolor2') lcolor(`linecolor2')) ///
        (kdensity mpg if foreign == 1, lcolor(`linecolor2') lpattern(solid) lwidth(medium)), ///
        ytitle("") xtitle("Mileage (mpg)") ///
        title("Density") ///
        legend(order(1 "Domestic" 3 "Foreign")) ///
        aspectratio(0.667)
    figexport "histogram_overlap"
    restore
end


main
