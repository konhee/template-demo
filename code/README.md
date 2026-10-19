# code/

All computation. Stages run in a one-way pipeline; `model/`, `explore/`, and `lib/`
sit off to the side.

```
fetch → build → analysis        (the pipeline; wired into the Makefile)
model                           (a model stage, e.g. MATLAB — off the build graph)
explore                         (exploratory, one-off — NOT in the build graph)
lib                             (shared helpers used by any stage)
```

## Workflow: issues and branches

Code development here starts either on a branch or in `code/explore/`, depending
on scope. A concrete, scoped issue on GitHub/GitLab (e.g. "add a binscatter of X
on Y") gets a branch created from it (most hosts offer a "create branch" action
on the issue, producing a `<number>-<slug>` name, e.g. `5-rent-decomposition`)
and a pull request straight into the Make graph (`fetch/`, `build/`, `analysis/`,
`model/`). A broad or open-ended issue ("explore raw rent data") starts in
`explore/` instead — there's often no concrete change yet to branch for. Once
exploration turns up something worth keeping, promote it: open (or narrow) an
issue, branch from it, and write the real version into `analysis/` or `model/`
there, deleting the now-superseded `explore/<task>/` folder as part of that PR
(git history keeps it recoverable) unless it holds something genuinely not
carried over. Trivial fixes (a typo, a comment) skip all of this; use judgment
on where the line is.

## Stages

- **`fetch/`** — Populate `data/raw/` from the source of truth: an API pull, a
  download, a scraper, an `scp` from a server, or a plain local copy. Non-deterministic
  or environment-specific, so it is **off the default build graph**: run it deliberately
  with `make fetch`, never as a side effect of a normal build. A project may have **no**
  fetch stage at all (the pipeline is a no-op when this folder is empty). Reads
  credentials from environment variables (see `.env.example`); never hard-code secrets.
  Stamp each pull with a `data/raw/<source>/PULLED_ON.txt`. Scripts are `.do`/`.py`/`.R`;
  a non-trivial copy gets a tiny wrapper (e.g. Python `shutil.copy`) rather than a bare
  `.sh`, for cross-platform uniformity.
- **`build/`** — Clean and transform: `data/raw` → `data/derived/build`. Pure function
  of the raw data. Run with `make data`.
- **`analysis/`** — Main analysis and estimation: `data/derived/build` → `output/`.
  Produces the curated figures and tables the documents reference (and may also write
  intermediate results to its own `data/derived/analysis/`). Run with `make analysis`.
- **`model/`** — A model stage: run a model and turn its output into figures/tables
  for the paper in `output/` (and may also write intermediate results to its own
  `data/derived/model/`). **Off the default build graph** (like `fetch`), because it's
  often slow or interactive — run it deliberately with `make model`. Empty if the
  project has no model. See `model/README.md`.
- **`explore/`** — Exploratory, one-off scripts. **Not a prerequisite of anything** in
  the Makefile, so `make` stays reproducible. Organize as one folder per line of
  inquiry (e.g. `2026-07-price-check/`). Each folder keeps its work colocated:
  - `output/` — figures/tables you're iterating on. **Tracked** (kept in git so you
    have history and coauthors can see them without rerunning your code).
  - `data/` — scratch intermediates. **Gitignored** (the global `**/data/` rule).

  When an exploration matures, *promote* it: move the script into `analysis/` and have
  it write to the top-level `output/`. Promotion — not directory nesting — is what
  keeps the curated `output/` clean.
- **`lib/`** — Shared helpers for the stages above: currently a Stata environment
  (`setup.do` bootstrap, `dependencies.do`, house graphics schemes) under `lib/stata/`;
  shared Python helpers would live alongside it as a package. See `lib/stata/README.md`.

## Languages

Mostly Stata (`.do`) and Python; the `model/` stage may also use MATLAB (`.m`), Julia
(`.jl`), or R (`.R`). The Makefile dispatches each by extension and runs a stage's
scripts in sorted-filename order (so a numbered prefix fixes their sequence). Stata and
MATLAB aren't assumed to be on `PATH`, so how to launch them is set in `config.mk` and
can be overridden per machine in `config.local.mk`.

## Naming conventions

The aim is that a filename tells you *what* a script does and *where its output goes*,
without opening it. The conventions:

- **Name by what the code does, not the language.** `price_rent_scatter.do`, not
  `stata_script_3.do`. If two languages cover one stage, that's fine — the folder is
  organized by task, never split into `python/` and `stata/` subfolders.
- **A script writes to an output subdir named after itself.** `price_rent_scatter.do`
  writes its figures to `output/figures/price_rent_scatter/`. Because the folder name
  matches the script's filename, any artifact is traceable back to the code that made
  it (no guessing which script produced a stray figure).
- **Number scripts only in a linear stage** — where step 2 must run after step 1
  (a solve before its plot). `step01_`/`step02_`; a letter-led, zero-padded prefix
  (MATLAB can't run an m-file whose name starts with a digit, and zero-padding keeps
  the sort correct past nine steps). Stages whose scripts are independent (most of
  `analysis/`) are **not** numbered — order there is meaningless and numbers rot.
- **No figure/table numbers in filenames.** Paper float numbers (Figure 3) change as
  the draft moves; a content name (`price_rent_timeseries`) doesn't. The LaTeX float
  environment assigns the number at compile time.
- **Keep a stage flat until it's unwieldy** (~15 scripts), then group **by topic**
  (`code/analysis/housing/`, `.../labor/`) — never by language. The Makefile collects
  scripts recursively, so nesting is safe.
