# reference/matlab/

The **permanent** house-style reference for MATLAB figures and tables. The MATLAB
companion to `../stata/`: it is **off the Make graph**, reads no project data, and
mirrors the same chart/table menu so a MATLAB-based analysis can match a Stata-, R-, or
Python-based one. Like `../r/`/`../py/`, it is **not** removed by
`init_project.py --drop-demo`; a project that wants it gone opts out explicitly with
`--drop-code-reference`.

**Deliberate exception to `code/model/README.md`'s division of labour.** That README
states the house convention for the model stage: *"MATLAB/Julia solve and export;
Stata/Python plot."* This folder's `figures.m`/`tables.m` do the opposite — draw and
tabulate directly in MATLAB — on purpose: the point of `code/reference/` is a complete,
harmonious house style across every language the pipeline dispatches (`.do`/`.py`/`.R`/
`.m`), so a MATLAB-heavy project can match the same look without leaving MATLAB. This
reference lives under `code/reference/`, not `code/model/`, precisely so it doesn't
contradict that convention — a real model step's own diagnostics should still follow
`code/model/README.md`'s plotting convention.

**No `sysuse auto`/`uslifeexp` equivalent exists in MATLAB**, so both scripts build off
`code/lib/matlab/mtcars.m` instead — a literal copy of R's base `mtcars` (same values as
`../py/`'s `mtcars.py`, no extra dependency, no network). The same substitution table
`../r/README.md`/`../py/README.md` use applies here:

| Stata (`auto`/`uslifeexp`) | MATLAB (`mtcars`) |
|---|---|
| `mpg` (mileage) | `mpg` (same variable) |
| `weight` | `wt * 1000` (weight in lbs) |
| `length` / a second continuous var | `hp` (horsepower) |
| a fourth continuous var (tables only) | `qsec` (1/4 mile time) |
| `rep78` (5-level category) | `cyl` (4/6/8 cylinders) |
| `foreign` (Domestic/Foreign group) | `am` (0/1, relabeled Automatic/Manual) |
| `uslifeexp`'s `le` by `year` | a synthetic rising-and-flattening curve |

Sample numbers match `../py/output/`/`../r/output/`'s fragments exactly — the point is
the *shape* and *look*, not the values (a nice bonus, not required).

Works in MATLAB or Octave (both confirmed on this project's dev box). `figures.m` needs
no toolbox beyond base MATLAB; `tables.m`'s regression table needs the Statistics and
Machine Learning Toolbox (`fitlm`).

Two scripts, both exporting exactly the way the real analysis scripts do:

- **`figures.m`** — one figure of each common chart type, rendered under **both** a mono
  and a color variant of one shared house style.
- **`tables.m`** — one of each common table type, writing `.tex` fragments in the same
  `\doublerule` / `\midrule` / `\sym{}`-star shape as the `esttab` fragments in
  `../stata/output/tables/`.

Workflow: **edit the theme or a table helper → rerun the script → eyeball `output/`**
(compare directly against the corresponding file in `../stata/output/`, `../r/output/`,
or `../py/output/`).

## Figures — `figures.m`

Each style (mono via a plain grey color order, color via MATLAB's default `lines`
colormap) is drawn directly in `figures.m` — there is no shared theme file to edit.
Each style is drawn once and written to a single `output/figures/` with the style as a filename suffix
(`scatter_mono.pdf`, `scatter_color.pdf`) — mirroring `../stata/output/figures/`'s flat,
suffix-tagged layout.

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
| `histogramOverlap` | kdensity + translucent histogram fill, overlaid by group |

Rule of thumb the two variants demonstrate, same as the Stata schemes: mono for
single-series figures, color only where groups must be told apart. Comment out any line
in `drawAll()` to skip a chart.

## Tables — `tables.m`

Builds one table of each kind and writes each as a `.tex` fragment into `output/tables/`.
`wrapHouseTable()` assembles the shared shape (`\doublerule` top, `\midrule` under the
header and before/after any stats block) that all four tables use; `stars()` applies the
house significance convention (`* 0.10 ** 0.05 *** 0.01`, wrapped in `\sym{}`). The
balance table's two-sample t-test uses `ttest2(..., 'Vartype', 'unequal')` (Welch's test)
to match R's `t.test()` default.

| Table         | What it exercises |
|---------------|-------------------|
| `summary`     | descriptive stats: mean / sd / min / max / N |
| `correlation` | pairwise correlation matrix (lower triangle) |
| `regression`  | nested OLS specs with stars, SEs, r2/N (`fitlm`) |
| `balance`     | two-group means, difference, significance (Welch's t-test) |

Comment out any line in the top-level script to skip a table.

## Running it

Off the Makefile — run by hand from anywhere in the repo:

```bash
matlab -batch "run('code/reference/matlab/figures.m')"
matlab -batch "run('code/reference/matlab/tables.m')"
```

Best-effort, also works with Octave:

```bash
octave --eval "run('code/reference/matlab/figures.m')"
octave --eval "run('code/reference/matlab/tables.m')"
```

## Seeing it in LaTeX

`output/` is **tracked**, but — like `../r/`'s and `../py/`'s artifacts — it is not
wired into `../latex/styleguide.tex`; that document renders the Stata sample outputs
only. Import a MATLAB `.tex` fragment or figure into `\housefigure`/`\housetable` the
same way a real `output/…` path would be (see the paper/notes preambles' house float commands) if you
want to see it compiled.
