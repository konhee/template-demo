# reference/stata/

The **permanent** house-style reference for Stata figures and tables. It is **off the
Make graph** and reads no project data (built entirely from Stata's built-in `sysuse`
datasets, fully offline), so it lives here as a living style guide rather than in the
pipeline. Unlike the demo pipeline, it is **not** removed by `init_project.py
--drop-demo`; a project that wants it gone opts out explicitly with
`--drop-code-reference`.

Two scripts, both exporting exactly the way the real analysis scripts do:

- **`figures.do`** — one figure of each common chart type, rendered under **both**
  a mono and a color Stata scheme (stock `s1mono`/`s2color`).
- **`tables.do`** — one of each common table type with the house `esttab` options
  (the options live inline; this file is their copy-paste reference).

Workflow: **edit a scheme or the `esttab` options → rerun the script → eyeball `output/`**
(or recompile `../latex/styleguide.tex`, which renders everything through the house
float commands).

## Figures — `figures.do`

One looped source runs the **same** chart menu once per scheme, writing both to a single
`output/figures/` with the scheme as a filename suffix (`scatter_mono.pdf`,
`scatter_color.pdf`) — one flat folder, mirroring the top-level `output/figures/`
convention, with each chart's two versions sorting adjacent for easy comparison. There is
no second script to keep in sync — change a chart once and both schemes pick it up.

| Chart        | What it exercises |
|--------------|-------------------|
| `scatter`    | single-group scatter, structural marker |
| `timeseries` | single line, top-left y-label, symmetric x ticks |
| `histogram`  | single distribution |
| `eventstudy` | coefficients ± 95% CI band around an event, ref period = 0 |
| `coefplot`   | coefficients across specs, horizontal, CI whiskers |
| `bar`        | grouped means, one series per group |
| `binscatter` | binned means by group |
| `kdensity`   | overlaid densities by group |
| `histogram_overlap` | kdensity + translucent histogram fill, overlaid by group |

Rule of thumb the two schemes demonstrate: **s1mono for single-series figures**,
**s2color only where groups must be told apart**. Comment out any line in `draw_all`
to skip a chart; add a scheme by extending the `SCHEMES` list at the top (each entry is a
`<scheme> <suffix>` pair).

## Tables — `tables.do`

Builds one table of each kind and writes each as a `.tex` fragment into `output/tables/`.
Each spells out the house `esttab` options inline (`label`, `compress`, `nonotes`, uniform
numbers, `\doublerule` top + `\midrule` rules), so it doubles as the copy-paste reference
for each table type.

| Table         | What it exercises |
|---------------|-------------------|
| `summary`     | descriptive stats: mean / sd / min / max / N (`estpost summarize`) |
| `correlation` | pairwise correlation matrix (`estpost correlate`) |
| `regression`  | nested OLS specs with stars, SEs, r2/N (`regress` + `eststo`) |
| `balance`     | two-group means, difference, significance (`estpost ttest`) |

Comment out any line in `main` to skip a table; each program clears stored estimates, so
call order doesn't matter.

## Running it

Off the Makefile — run by hand from anywhere in the repo (`setup.do` finds the root):

```bash
stata-mp -b do code/reference/stata/figures.do
stata-mp -b do code/reference/stata/tables.do
```

or double-click / `do` either from this folder.

## Seeing it in LaTeX

`output/` is **tracked** so its figures and fragments are available to coauthors without
rerunning Stata. The sibling `../latex/styleguide.tex` renders these figures and table
fragments through the house float commands (`\housefigure`, `\housetable`) — that
compilable document is the place to see the LaTeX import end to end and to copy a call for
the real paper.
