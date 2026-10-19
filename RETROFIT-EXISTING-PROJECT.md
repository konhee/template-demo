# Retrofitting this scaffold into an existing project

**Audience:** anyone grafting this template's build scaffold onto a repo that
already has its own code and history. Goal: add the
orchestration (Makefile, config, `code/lib`, portable path bootstrap), the house LaTeX
style, and conform the repo to the template layout **while preserving the existing git
history**. Work on a branch; verify with `make` before merging.

Companion: `SETUP-NEW-PROJECT.md` (fresh clone from the GitHub template). This guide
reuses that one's **§1 identity rename** and **§2 machine setup** verbatim — do them here
too; they aren't repeated below.

Precondition: you have both the target repo and a copy of this template available (e.g.
the template as an additional working directory for the session). Throughout, "template"
= this scaffold, "target" = the repo being retrofitted.

---

## 1. Branch

In the target repo: `git checkout -b adopt-template`. All work lands here; merge only
after `make` verifies (§8).

## 2. Graft the orchestration (pure addition — no conflicts)

Copy these from the template into the target's root, then `git add`:
- `Makefile`, `config.mk`, `config.local.mk.example`
- `environment.yml`, `.env.example`
- `code/lib/` (the Stata `setup.do`/`dependencies.do` bootstrap + house schemes, and any
  Python lib)
- `code/reference/` (the permanent coding + house-style guide — skeletons, the figure/table
  look, the float commands). Off the Make graph and runs on a bare clone, so it grafts in
  cleanly; kept by default. Drop it only if the target doesn't want it (`git rm -r
  code/reference`).
- `assets/` (fonts + placeholder floats), `.gitignore` (merge with the target's if it has
  one — union the rules; keep the template's `**/data/`, `.make/`, aux-file, and env
  entries)
- `SETUP-NEW-PROJECT.md`, `RETROFIT-EXISTING-PROJECT.md`, `README.md` (the target may
  want to keep its own README content — merge rather than clobber)

(The house LaTeX style — preambles, `supp/`, float commands — is grafted
separately in §4, once the target's docs are in place.)

Then apply **§1 (identity rename)** and **§2 (machine setup)** from `SETUP-NEW-PROJECT.md`
— but the `init_project.py` shortcut in that §1 doesn't apply here: the script isn't
grafted into the target, and your docs aren't named `template-*.tex`, so do the identity
rename by hand.

## 3. Conform the layout (use `git mv` to preserve history)

Map the target's directories onto the template's canonical structure. Typical moves
(adapt to what the target actually has):

| Template slot | What lands here |
|---|---|
| `code/fetch/` | API pulls / scrapers → `data/raw` |
| `code/build/` | cleaning scripts: `data/raw` → `data/derived/build` |
| `code/analysis/` | estimation/figures: `data/derived/build` → `output/` |
| `code/model/` | a model stage → `data/derived/model/` + `output/` (off the Make graph) |
| `code/explore/` | the target's own exploratory one-offs / scratch analyses (off the Make graph) |
| `code/lib/stata/` | shared `.do`/`.ado`, house schemes, existing package-install script |
| `writing/{paper,slides,notes}/` | the authored documents + their `supp/` |
| `output/{figures,tables}/` | curated, paper-facing artifacts (tracked) |
| `data/{raw,derived}/` | data (gitignored) |
| `assets/fonts/` | font files the preambles load |

Use `git mv` so blame/history follow. After moving, grep for now-broken relative paths
(`\input`, `\includegraphics`, `include`, data reads) and fix them. (Font loading and the
rest of the house LaTeX style are handled next, in §4.)

## 4. Adopt the house LaTeX style

The target keeps its *content* but takes on the template's document machinery. Copy the
template's `supp/` scaffolding into each of the target's `writing/{paper,slides,notes}/`,
then reflow the existing prose into it — don't hand-merge two preambles.

- **Preambles** — bring over `writing/paper/supp/preamble.tex`,
  `notes/supp/preamble-notes.tex`, `slides/supp/preamble-slides.tex`. These carry the
  runtime-absolute font loading (`../../assets/fonts/`), `microtype
  expansion=false`, and the TeXLive-2019 guards. Replace the target's own preamble rather
  than splicing; then re-add any *genuinely project-specific* macros the target defined.
- **House float commands** — `\housefigure` / `\housetable` (paper + notes; panels given
  as `\panel{...}`) and the slide spacing macros come with those preambles. Convert the
  target's hand-written figure/table floats to these calls.
- **Bibliography** — all three documents use the stock `aer.bst` (already what the
  template's preambles set); no vendored `.bst` file to copy.
- **Subfiles wiring** — if the target's paper is monolithic, adopt the template's
  `subfiles` + `\maindocument` split (`-combined` / `-body` / `-appendices`) only if you
  want standalone-compilable parts; otherwise keep the target's structure and just take the
  preamble + float commands. This one is optional.

Then apply `SETUP-NEW-PROJECT.md` **§1's document rename** (`git mv` the docs to
`<project>-*.tex`, fix `\documentclass`/`\subfile`/`\externaldocument` cross-refs, run the
grep check). Compile each document before moving on.

## 5. Migrate to the portable path bootstrap (the core work)

Existing analysis code likely hardcodes machine paths (`cd /Users/.../project/...`) and
brittle relative globals (`global datadir "../../../data/"`). These are exactly what the
scaffold removes: every pipeline script should instead locate and run `setup.do`, which
climbs to the repo root via sentinels and normalizes `cwd`, so all downstream paths are
relative to root and work on any machine.

For each `.do` in `code/build`/`code/analysis`:
- Delete the hardcoded `cd` and ad-hoc directory globals.
- Add the bootstrap that finds `setup.do` from either the repo root (`make`) or the
  script's folder (double-click), per `code/lib/stata/README.md`, and structure the script
  as `main` → `init` (runs the bootstrap) → work, matching the template's analysis scripts.
- Replace path globals with the ones `setup.do`/`init` establish (`data/derived/...`,
  `output/...` relative to root).

Do the equivalent for Python stages: read inputs/write outputs by paths relative to a
root the script resolves, not an absolute machine path.

## 6. Reconcile dependencies into the two-tier model

- **Stata**: fold the target's existing package-install script into
  `code/lib/stata/dependencies.do`'s `required` list (Tier 2, `ssc install` on demand);
  vendor anything offline-only into `code/lib/stata/` (Tier 1). See its README.
- **Python**: add every third-party import the pipeline uses to `environment.yml`. If the
  target had a `requirements.txt`/other env file, migrate its real deps and remove it.

## 7. Data-tracking decision

The template gitignores all of `data/`; existing repos often commit `.dta`/`.csv`. For
each committed data file decide:
- **Regenerable build product** (output of a `code/build` step) → move to
  `data/derived/build`, let `.gitignore` drop it, `make data` rebuilds it.
- **Irreplaceable raw source** (a one-off pull, hand-collected, or upstream that may
  vanish) → move to `data/raw` and add a `PULLED_ON.txt` provenance stamp; if it must stay
  in git, add a narrow `.gitignore` exception rather than un-ignoring `data/` wholesale.

Flag this decision to the user rather than guessing — losing an irreplaceable raw file to
`.gitignore` is the one destructive mistake here.

## 8. Verify, then merge

Build the pipeline in stages so a failure localizes:
```bash
make data       # build → data/derived/build
make analysis   # → output/
make docs       # compile paper + slides
```
(Or `make all`.) Fix until green.

Then de-template and finalize, as in `SETUP-NEW-PROJECT.md` §3 and §7: re-voice the
grafted `README.md` from "this is a template" into the project's own (keeping
the still-true conventions — pipeline, layout, float commands, schemes, `init`/`main`),
and `git rm SETUP-NEW-PROJECT.md RETROFIT-EXISTING-PROJECT.md` once you're done following them. (The
target may already have its own README — merge, keeping its project voice.)

Then commit on `adopt-template` and merge to the target's main branch. The payoff: the
repo now runs `make all` on any machine with no hardcoded paths, tracks `output/` +
compiled PDFs for coauthors, and shares the template's cross-platform font/scheme
handling.
