# template

Created by [Konhee Chang](https://github.com/konhee).

A template repository for research projects: a one-way data pipeline
(fetch → build → analysis → model) feeding LaTeX documents (paper, slides, notes),
all orchestrated by a Makefile.

## Starting a new project

Created this from the template (GitHub/GitLab "Use this template", or a fresh clone)?

1. **Stamp the identity** — rename the doc files, fix cross-refs, set the conda env
   name, all mechanically:
   ```bash
   python init_project.py <slug>        # e.g. vantage; add --dry-run to preview
   ```
   Add `--drop-demo --drop-code-reference --self-destruct` to also clear the shipped
   demo pipeline, the `code/reference/` house-style guide, and the setup guides + this
   script itself.
2. **Finish setup by hand** — machine setup (conda env, `config.local.mk`, `.env`)
   and re-voicing `README.md` as *this* project. Full walkthrough:
   **[`SETUP-NEW-PROJECT.md`](SETUP-NEW-PROJECT.md)**.

Grafting this scaffold onto a repo that **already exists**? See
**[`RETROFIT-EXISTING-PROJECT.md`](RETROFIT-EXISTING-PROJECT.md)** instead.

## Structure

```
template/
├── Makefile              # orchestrates everything (see targets below)
├── config.mk             # shared build config (committed); override per-machine in config.local.mk
├── .env.example          # copy to .env; API credentials for code/fetch
│
├── assets/
│   ├── fonts/            # custom fonts used in paper, slides, and notes
│   └── placeholders/     # placeholder tables and figures
│
├── data/                 # ALL gitignored
│   ├── raw/              # immutable source data (written by code/fetch or placed by hand) [RAW_DIR]
│   └── derived/          # regenerable data, producer-namespaced by stage [DERIVED_DIR]
│                         # derived/{build,analysis,model}/ — write-own, read-any
│
├── code/
│   ├── fetch/            # API pulls / scrapers → data/raw          (make fetch; off default graph)
│   ├── build/            # data/raw → data/derived/build            (make data)
│   ├── analysis/         # data/derived/build → output              (make analysis)
│   ├── model/            # solve a quantitative model → output      (make model; off default graph)
│   ├── explore/          # exploratory one-offs — NOT in the build graph
│   ├── reference/        # permanent coding + house-style guide — off the graph
│   └── lib/              # Python/Stata/R/MATLAB helpers
│
├── output/
│   ├── figures/          # paper-facing figures [FIG_DIR]
│   └── tables/           # paper-facing tables [TAB_DIR]
│
├── writing/              # authored material
│   ├── references.bib    # shared bibliography
│   ├── notebook/         # informal running notes (meeting logs, ideas) — TRACKED, off the graph
│   ├── paper/            # authored + compiled (subfiles: body/appendices/combined)
│   │   └── archive/      # frozen final PDFs (submissions), YYYY-MM-occasion.pdf
│   ├── slides/           # authored + compiled (beamer 16:9)
│   │   └── archive/      # frozen final PDFs (as presented at venues)
│   └── notes/            # authored + compiled (model appendix, internal memos)
│
└── references/           # collected external material
    ├── data-dictionaries/
    └── literature/
```

## Data flow
Data flows one direction:

```
code/fetch → data/raw → code/build → data/derived/build → code/analysis (→ code/model) → output/ → writing/
```

## Make targets

| Target | Does |
|---|---|
| `make fetch` | Populate `data/raw/` from the source of truth (run deliberately; off the default graph) |
| `make data` | Clean `data/raw` → `data/derived/build` |
| `make analysis` | Produce/refresh figures/tables in `output/` |
| `make model` | Solve the quantitative model → `output/` (run deliberately; off the default graph) |
| `make paper` / `slides` / `notes` | Compile one document from the **tracked** `output/` |
| `make docs` | Compile `paper` + `slides` (notes excluded; run `make notes`) |
| `make all` | `data` → `analysis` → `docs` (does **not** fetch or solve the model) |
| `make full` | `data` → `analysis` → `model` → `docs` (rebuild everything downstream of `data/raw`; does **not** fetch) |
| `make clean` | Remove `data/derived`, `output/` artifacts, LaTeX aux |
| `make distclean` | `clean` + remove fetched raw data |

`make docs` compiles the committed `output/` artifacts and **never** runs the
pipeline, so a fresh clone builds every document with no `data/` and no `fetch`.
The flip side: after editing an analysis script, run `make analysis` (or `make
all`) to refresh `output/` — `make docs` alone won't. `fetch` is whatever
populates `data/raw` (an API pull, a scraper, an `scp` from a server, a local
copy); a project may have no `fetch` stage at all, and the pipeline still runs when `code/fetch/` is empty.

## Workflow: issues and branches

Substantive changes go through an issue + branch + pull request — see
`code/README.md` and `writing/README.md`.

## Setup on a new machine

1. Create the Python environment (once per machine — `make` never builds it):
   `conda env create -f environment.yml`. Alternatively, use the generic `base` environment from the Anaconda installation.
2. Copy `config.local.mk.example` → `config.local.mk` and set your machine's tool
   paths there (do not edit `config.mk`; local overrides win automatically). Point
   `PYTHON` at the env's interpreter by **absolute path** so `make` uses it without
   you having to `conda activate` first — get the path with
   `conda run -n template python -c "import sys; print(sys.executable)"`. Set `STATA`
   if Stata isn't on `PATH` with the default name.
3. Copy `.env.example` → `.env` and fill in any API keys that `code/fetch/` scripts need
   (the demo's FRED pull needs none).
4. `make full`.

Stata packages install themselves on first run (see `code/lib/stata/README.md`).

## Requirements

- **LaTeX**: TeXLive (targets Windows TeXLive 2019 without admin access). Documents
  compile with `lualatex` via `latexmk`.
  cross-platform constraints.
- **Python** (via conda; see `environment.yml`) and **Stata** for the analysis pipeline.
