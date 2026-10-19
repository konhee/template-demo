# reference/latex/

A compilable **permanent reference** for the house figure and table style — the LaTeX
companion to `../stata/` beside it. `styleguide.tex` renders the house float commands
(`\housefigure`, `\housetable`) on the sample artifacts produced by `../stata/`, so you
can eyeball the whole style in one document. Like its sibling it is **off the Make graph**
and reads no project data. It is **not** removed by `init_project.py --drop-demo`; a
project that wants it gone opts out explicitly with `--drop-code-reference`.

## What it shows

Two sections:

- **Figures** — `\housefigure` in its several shapes (single figure, 2-per-row grid, and
  panels with lettered subcaptions and their own labels — all one command, panels given as
  `\panel{...}`), rendered on the `figures.do` PDFs.
- **Tables** — `\housetable` on the four `tables.do` fragments (summary,
  correlation, regression, balance).

The commands themselves are defined in the shared preamble block, not here — see
`writing/README.md` for the house float commands and `../stata/` for the house `esttab`
options. This document only *calls* them, so it doubles as usage reference: copy a call,
swap the paths.

## Running it

Off the Makefile — compile in place (its `supp/preamble-notes.tex` wires up the custom
fonts with a system-font fallback, so it builds standalone):

```bash
cd code/reference/latex && latexmk -lualatex styleguide.tex
```

It `\includegraphics`/`\input`s `../stata/`'s tracked `output/` (figures from
`../stata/output/figures/`, tables from `../stata/output/tables/`), so regenerate those
(rerun `figures.do` / `tables.do`) after editing a scheme or the `esttab` options, then
recompile to compare. `styleguide.pdf` is tracked so coauthors see the current style
without a Stata or LaTeX run.
