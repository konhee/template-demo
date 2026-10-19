# Starting a new project from this template

**Audience:** anyone configuring a fresh clone of the template to start a new repository.
Precondition: this repo was created via GitHub **Use this template** and cloned. Goal:
stamp the project identity, set up the machine, re-voice the docs as the project's own,
and clear the shipped demo + scaffolding. The docs
already reference neutral placeholders, so **nothing here risks breaking the build** — the
repo compiles green before and after. Do the sections in order; commit at each mark.

Companion: `RETROFIT-EXISTING-PROJECT.md` (grafting this scaffold onto a repo that already exists).

Shipped content that isn't the user's project, and its fate:
- **Worked pipeline demo** — `code/{fetch,build,analysis}` price/rent scripts and a
  `code/model/` Solow example, plus their `output/` artifacts. A runnable `make all`
  (and `make model`) example; delete when no longer needed (§4).
- **Coding + house-style reference** — `code/reference/`. A *permanent* guide (skeletons +
  the house figure/table look), kept by default; delete only if a project wants it gone (§5).
- **Placeholder floats** — the `\housefigure`/`\housetable` calls in `writing/` already
  point at `assets/placeholders/`. Keep them; swap in real `output/…` paths as your
  analysis produces artifacts (§6).

---

## 1. Stamp the project identity

**Shortcut:** the mechanical parts of this section are automated —
`python init_project.py <project>` does the renames, cross-ref fixes, and
`environment.yml` env-name stamp below, then stages the changeset and prints the commit
command (it never commits). Add `--dry-run` to preview. The steps below are the spec it
implements; do them by hand only if you prefer. (The script leaves §2/§3 — machine setup
and re-voicing prose — to you, and can also clear the shipped extras: `--drop-demo
--drop-code-reference`.)

Ask the user for the project slug (e.g. `voucher`) if not given. Replace `template` as an
*identifier* (not in prose):

- **`environment.yml`**: `name: template` → `name: <project>`.
- **Document files**: `git mv` each `writing/**/template-*.tex` to `<project>-*.tex`
  (paper has `-combined`, `-body`, `-appendices`; slides `-slides`; notes `-notes`). The
  Makefile globs `*.tex`, so no Makefile edit — but fix the cross-refs between the paper
  files: `\documentclass[template-combined]{subfiles}`, `\subfile{...}`, and
  `\externaldocument{...}` all name siblings by the old stem. After renaming, verify none
  remain:
  ```bash
  git grep -nE '\\(subfile|documentclass|externaldocument)\{[^}]*template' -- 'writing/**/*.tex'
  ```
  Expect zero hits (a stray one yields a silent `??` ref, not an error — grep is the check).

Commit: **"Stamp <project> identity"**.

## 2. Set up this machine (once per machine; `make` never does it)

1. `conda env create -f environment.yml` (creates env `<project>`).
2. `cp config.local.mk.example config.local.mk`; set `PYTHON` to the env interpreter's
   **absolute path** (see that file's comments), and `STATA` if not on `PATH`.
3. `cp .env.example .env`; fill API keys (only needed for `make fetch`).

Confirm the toolchain works: `make docs` should build the paper + slides from the
tracked `output/` (against the placeholder floats) — it runs no pipeline and needs no
`data/`, so it works on a fresh clone. If it fails, fix the environment before going
further.

## 3. Make it yours (de-template the docs)

`README.md` still opens as *the template* ("A template repository for
empirical research projects…"). **Rewrite, don't scrub** — re-voice them from "here is a
scaffold that provides X" to "here is this project." ~90% of both files stays accurate and
should stay: pipeline structure, directory layout, Makefile/target reference, LaTeX+font
mechanics, house float commands and schemes, the `init`/`main` Stata convention.

- **Drop only the template/demo framing**: the `# template` title, the "template
  repository / standardized structure" blurb, and any "here's a shipped demo you'll
  delete" / "style lookup card" narration. Keep the *conventions* those demos illustrate;
  drop the "this is a demo" voice — this holds whether or not §4/§5 have removed the files
  yet, so no re-edit is needed later.
- **Don't invent the project description.** The real title/authors/topic are the author's
  to write — leave a marker like `> _One-line project description — author fills in._`
  rather than fabricating one.
- **Kill lingering `template` identifiers** here too: README's `conda run -n template …`
  example, any layout tree showing `template/`, etc.

Commit: **"De-template README/CLAUDE for <project>"**.

## 4. Clear the worked pipeline demo (optional, when ready)

The demo has two parts: the price/rent pipeline (`code/fetch/fetch_fred.py`,
`code/build/build_price_rent.py`, `code/analysis/price_rent_*.do`) runs end-to-end via
`make all`, and a Solow model example (`code/model/step01_solve.m` +
`step02_plot_transition.do`) runs via `make model` — each with its `output/` artifacts.
Keep them as long as they're a useful reference for the fetch→build→analysis wiring and
the model stage. No document cites them, so deleting never affects the build:
```bash
git rm code/fetch/fetch_fred.py code/build/build_price_rent.py code/analysis/price_rent_*.do
git rm code/model/step01_solve.m code/model/step02_plot_transition.do
git rm -r output/figures/price_rent_scatter output/figures/price_rent_timeseries output/figures/solow_transition
git rm output/tables/price_rent_corr.tex
```
(Or in one step: `python init_project.py <slug> --drop-demo`.) Commit: **"Remove demo
pipeline"**. (`make docs` still builds — the floats point at `assets/placeholders/`,
untouched by this.)

## 5. Coding + house-style reference — keep by default

`code/reference/` is the *permanent* coding + house-style guide: `skeletons/` (copy-to-start
scripts), `stata/` (the figure/table look), and `latex/` (the float commands in use). It is
off the build graph and runs on a bare clone, so keep it — it stays useful as a lookup card
for the life of the project. If a project genuinely wants it gone, remove the whole folder:
```bash
git rm -r code/reference     # or: python init_project.py <slug> --drop-code-reference
```

## 6. First real work

Clean, named, compiling base. Then: point `code/fetch/` at real sources (add imports to
`environment.yml` in the same commit), add Stata packages to
`code/lib/stata/dependencies.do` as used, write `code/build/`→`code/analysis/` per the
`init`/`main` convention pointing at top-level `output/`. As each real artifact appears,
swap the matching placeholder path in `writing/` (`assets/placeholders/placeholder-figure.pdf`
→ your `../../output/figures/…`) and write a real caption.

Fill in the docs' own title/author/sections directly in the `writing/**/*.tex` files —
they ship with leftover placeholder content you can just overwrite.

Payoff, for context: `make all` runs the whole pipeline on any machine with no hardcoded
paths; `output/` + compiled PDFs are tracked so coauthors build docs without rerunning
analysis; fonts are cross-platform (incl. Windows TeXLive 2019). See `README.md`.

## 7. Finalize (remove the scaffolding)

Last step, deliberately after everything else — these guides are the checklist you're
still following, so they self-delete only once you're done with them:
```bash
git rm SETUP-NEW-PROJECT.md RETROFIT-EXISTING-PROJECT.md
```
Commit: **"Remove template setup guides"**.
