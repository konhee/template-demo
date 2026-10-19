# writing/

Authored prose, from informal running notes through compiled documents — the things you
write and put out. (Material you *consult* rather than author lives in the top-level
`references/`.) It runs a maturity gradient: `notebook/` → `notes/` → `paper/` (with
`slides/` a presentation cut of the paper).

## Workflow: issues and branches

Substantive changes to `notes/`, `paper/`, or `slides/` go through an issue on
GitHub/GitLab, a branch created from it (e.g. `93-write-data-section`), and a
pull request into `master` — same mechanic as `code/`.

## Notebook (not built)

- **`notebook/`** — the informal front: meeting logs, scattered thoughts, early ideas,
  in whatever format they arrive (incl. scans of handwritten pages). Tracked but *not*
  compiled, and the opposite of `temp/` scratch — this is the raw material a write-up
  grows from. Promote a note into `notes/` (and onward to `paper/`) as it firms up, the
  same way `code/explore/` graduates into `code/analysis/`. See its own README.

## Documents (built by `make`)

- **`paper/`** — the paper. Modular via the `subfiles` package: `template-body.tex`,
  `template-appendices.tex`, and `template-combined.tex` (full paper + appendices).
  Compile with `make paper`.
- **`slides/`** — beamer presentation, 16:9, with notes support. `make slides`.
- **`notes/`** — internal notes (model appendix, memos). `make notes`.

Each has a `supp/` subdirectory with its `preamble*.tex`, any section files it splits
into. See `../SETUP-NEW-PROJECT.md` and `../RETROFIT-EXISTING-PROJECT.md` for the
subfiles/preamble/font machinery and Windows TeXLive 2019 constraints.

## Archived versions

`paper/archive/` and `slides/archive/` hold **frozen final PDFs** at milestones
(a submission, slides as presented at a venue) — named `YYYY-MM-<occasion>.pdf`. These
are permanent records, never regenerated; the living `template-*.pdf` in each folder is
the current build. See each `archive/README.md`.

## Bibliography

`references.bib` here is the single shared bibliography. Each document points at it with
`\bibliography{../references}` — a one-level climb, the same ancestor-anchored pattern the
preambles use for fonts — so there is one source of truth and nothing to keep in sync.

## Figures

Generated figures/tables come from the top-level `output/` (referenced as
`../../output/figures/...`). Hand-drawn / illustrative figures that are *not* generated
live with their document under `supp/figures/`.

## House float commands

The paper and notes preambles (`paper/supp/preamble.tex`,
`notes/supp/preamble-notes.tex`) define two commands for the common float shapes, so a
figure or table is one call rather than a hand-written `figure`/`table` environment. Each
takes a **body of `\panel{...}` calls** as its first mandatory arg, then
`{caption}{label}{notes}` as the last three (label or notes may be empty); the starred
form tightens the float up under an immediately preceding heading. A panel is
`\panel[sub=<subcaption>, label=<sublabel>]{path}`, both keys optional — omit `sub=` for a
plain unlettered panel, `label=` for no `\label`.

- **`\housefigure[<width>]{ \panel{...} \panel{...} ... }{caption}{label}{notes}`** —
  `<width>` is the uniform width of every panel (default `\textwidth` for one panel,
  `0.5\textwidth` for 2+). Rows wrap by how many `<width>`-wide panels fit across
  `\textwidth` (`[\textwidth]`=1/row, `[.5\textwidth]`=2/row, `[.33\textwidth]`=3/row; a
  short last row centers), giving the usual 2×1 / 2×2 / 2×3 grids. A panel with `sub=`
  gets a lettered subcaption and its own label (reference it with `\autoref{sublabel}`); a
  bare `\panel{path}` is just an image, so an all-plain call renders as a simple
  single/grid figure. `\housesubfigure` is a kept alias of `\housefigure`.
- **`\housetable{ \panel{frag.tex} ... }{caption}{label}{notes}`** — one `\panel`
  `\input`s a bare booktabs fragment (from `output/tables/`) into a `subtable` inside a
  `table` float; multiple panels stack vertically, each with an `A. <sub>` header when
  `sub=` is given. Like a subfigure, a panel with `label=` is cross-referenceable
  (`\subref{sublabel}` → `A`, `\autoref` → the panel number+letter).

Non-regular floats (sideways, `\ContinuedFloat` across a page break, bespoke layouts)
stay hand-written. Slides place floats manually and do **not** carry these commands. Both
commands are demoed end-to-end in `code/reference/latex/styleguide.tex`.
