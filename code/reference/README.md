# code/reference/

The **permanent coding + house-style reference** — the "how we write code here" guide.
Copy from it when starting a new script; consult it for the house figure/table look. It
is **off the Make graph** and runs on a bare clone (everything is built from Stata's
`sysuse` datasets or a literal frame, so no `data/` is needed).

**It survives a demo scrub.** `init_project.py --drop-demo` removes the price/rent
*wiring* demo (`code/{fetch,build,analysis}/price_rent_*`) — that teaches how the pipeline
stages connect and is meant to be replaced by real scripts. This folder teaches something
different and lasting: how to *write* one script and the house look. A project that wants
it gone opts out explicitly with `init_project.py --drop-code-reference`.

## Layout

```
code/reference/
├── skeletons/      copy these to start a new script
│   ├── analysis.do   bare init/main/worker Stata script (runs on sysuse auto)
│   ├── analysis.py   minimal read → transform → write Python script
│   ├── analysis.R    the same read → transform → write shape in base R
│   └── analysis.m    MATLAB model script: solve → export data (a .do/.py plots it)
├── stata/          the house figure + table look
│   ├── figures.do    one figure of each chart type, both house schemes
│   ├── tables.do     one of each table type, house esttab options (inline)
│   └── output/       tracked sample artifacts (figures/, tables/)
├── r/              the house figure + table look, in R (mirrors stata/)
│   ├── figures.R     one figure of each chart type, mono + color ggplot2 theme
│   ├── tables.R      one of each table type, same \doublerule/\midrule shape
│   └── output/       tracked sample artifacts (figures/, tables/)
├── py/             the house figure + table look, in Python (mirrors stata/)
│   ├── figures.py    one figure of each chart type, mono + color matplotlib theme
│   ├── tables.py     one of each table type, same \doublerule/\midrule shape
│   └── output/       tracked sample artifacts (figures/, tables/)
├── matlab/         the house figure + table look, in MATLAB (mirrors stata/)
│   ├── figures.m     one figure of each chart type, mono + color house style
│   ├── tables.m      one of each table type, same \doublerule/\midrule shape
│   └── output/       tracked sample artifacts (figures/, tables/)
└── latex/          the LaTeX float commands in use
    └── styleguide.tex  \housefigure / \housetable on the stata/ artifacts
```

## Where to look

- **Starting a new pipeline script?** Copy `skeletons/analysis.do` or `analysis.py` and
  fill in the worker. They demonstrate the conventions (the `setup.do` bootstrap, one
  `main` calling workers, root-anchored paths, one script → one output subdir) with the
  analysis stripped out.
- **Making a figure or table?** See `stata/` — `figures.do` for the graph schemes,
  `tables.do` for the copy-paste `esttab` option strings — or `r/`/`py/`/`matlab/` for
  the same chart/table menu in ggplot2/matplotlib/MATLAB, all built on `mtcars` in place
  of `sysuse auto`. Each subfolder has its own README. (`matlab/` is a deliberate
  exception to `code/model/README.md`'s "MATLAB exports, Stata/Python plots" division of
  labour — see `matlab/README.md`.)
- **Placing a float in LaTeX?** See `latex/styleguide.tex` — every shape of `\housefigure`
  and `\housetable`, rendered on the `stata/` artifacts. `styleguide.pdf` is tracked, so
  you can view it without compiling.

Nothing here is imported by the paper or run by `make`; it is reference only.
