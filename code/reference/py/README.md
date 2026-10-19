# reference/py/

The **permanent** house-style reference for Python figures and tables. The Python
companion to `../stata/`: it is **off the Make graph**, reads no project data, and
mirrors the same chart/table menu so a Python-based analysis can match a Stata- or
R-based one. Like `../r/`, it is **not** removed by `init_project.py --drop-demo`; a
project that wants it gone opts out explicitly with `--drop-code-reference`.

**No `sysuse auto`/`uslifeexp` equivalent exists in pandas**, so both scripts build off
`code/lib/py/mtcars.py` instead — a literal copy of R's base `mtcars` (no extra
dependency, no network). The same substitution table `../r/README.md` uses applies here,
since both scripts build on the same `mtcars` values:

| Stata (`auto`/`uslifeexp`) | Python (`mtcars`) |
|---|---|
| `mpg` (mileage) | `mpg` (same variable) |
| `weight` | `wt * 1000` (weight in lbs) |
| `length` / a second continuous var | `hp` (horsepower) |
| a fourth continuous var (tables only) | `qsec` (1/4 mile time) |
| `rep78` (5-level category) | `cyl` (4/6/8 cylinders) |
| `foreign` (Domestic/Foreign group) | `am` (0/1, relabeled Automatic/Manual) |
| `uslifeexp`'s `le` by `year` | a synthetic rising-and-flattening curve (no pandas/numpy time series matches the shape) |

Sample numbers match `../r/output/`'s fragments exactly — `mtcars.py` is sourced from the
same R dataset — but the point is the *shape* and *look*, not the values (a nice bonus,
not required).

Needs, beyond `pandas` (already a required dependency): `matplotlib` (`figures.py`),
`scipy` (`figures.py`'s kdensity charts, `tables.py`'s balance t-test), `statsmodels`
(`tables.py`'s regression). Install once with:

```bash
conda env update -f environment.yml
```

Two scripts, both exporting exactly the way the real analysis scripts do:

- **`figures.py`** — one figure of each common chart type, rendered under **both** a
  mono and a color variant of one shared matplotlib theme.
- **`tables.py`** — one of each common table type, writing `.tex` fragments in the same
  `\doublerule` / `\midrule` / `\sym{}`-star shape as the `esttab` fragments in
  `../stata/output/tables/`.

Workflow: **edit the theme or a table helper → rerun the script → eyeball `output/`**
(compare directly against the corresponding file in `../stata/output/` or `../r/output/`).

## Figures — `figures.py`

Each style (mono via matplotlib's built-in `grayscale` style, color via its plain
default) is drawn directly in `figures.py` — there is no shared theme file to edit.
Each style is drawn once and written
to a single `output/figures/` with the style as a filename suffix (`scatter_mono.pdf`,
`scatter_color.pdf`) — mirroring `../stata/output/figures/`'s flat, suffix-tagged layout.

| Chart        | What it exercises |
|--------------|-------------------|
| `scatter`    | single-group scatter, structural marker |
| `timeseries` | single line, top-left y-label, symmetric x ticks |
| `histogram`  | single distribution |
| `eventstudy` | coefficients ± 95% CI band around an event, ref period = 0 |
| `coefplot`   | coefficients across specs, horizontal, CI whiskers |
| `bar`        | grouped means, one series per group |
| `binscatter` | binned means by group (mono: filled vs. hollow marker) |
| `kdensity`   | overlaid densities by group (mono: solid vs. dashed line) |
| `histogram_overlap` | kdensity + translucent histogram fill, overlaid by group |

Rule of thumb the two variants demonstrate, same as the Stata schemes: mono for
single-series figures, color only where groups must be told apart. Comment out any line
in `draw_all()` to skip a chart.

## Tables — `tables.py`

Builds one table of each kind and writes each as a `.tex` fragment into `output/tables/`.
`wrap_house_table()` assembles the shared shape (`\doublerule` top, `\midrule` under the
header and before/after any stats block) that all four tables use; `stars()` applies the
house significance convention (`* 0.10 ** 0.05 *** 0.01`, wrapped in `\sym{}`). The
balance table's two-sample t-test uses `scipy.stats.ttest_ind(..., equal_var=False)`
(Welch's test) to match R's `t.test()` default.

| Table         | What it exercises |
|---------------|-------------------|
| `summary`     | descriptive stats: mean / sd / min / max / N |
| `correlation` | pairwise correlation matrix (lower triangle) |
| `regression`  | nested OLS specs with stars, SEs, r2/N (`statsmodels.OLS`) |
| `balance`     | two-group means, difference, significance (Welch's t-test) |

Comment out any line in `main()` to skip a table.

## Running it

Off the Makefile — run by hand from anywhere in the repo:

```bash
python3 code/reference/py/figures.py
python3 code/reference/py/tables.py
```

## Seeing it in LaTeX

`output/` is **tracked**, but — like `../r/`'s artifacts — it is not wired into
`../latex/styleguide.tex`; that document renders the Stata sample outputs only. Import a
Python `.tex` fragment or figure into `\housefigure`/`\housetable` the same way a real
`output/…` path would be (see the paper/notes preambles' house float commands) if you want to see it
compiled.
