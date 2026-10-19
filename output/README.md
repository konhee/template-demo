# output/

The **curated, paper-facing** results: figures and tables produced by `code/analysis`
(and `code/model`) that the documents in `writing/` reference. **Tracked in git** so
coauthors can compile the paper without rerunning the analysis (or having the underlying
data).

```
output/
├── figures/    # .pdf / .png referenced by writing/{paper,slides,notes}
└── tables/     # .tex fragments \input by the documents
```

## What belongs here

Only **promoted, final** artifacts. Everything speculative or exploratory stays in
`code/explore/<task>/output/` until the script that makes it is promoted into
`code/analysis/` (or `code/model/`).

This directory provides a stable mapping between analysis and writing: a document
references `../../output/figures/fig2_labor_supply.pdf` or
`../../output/tables/tab3_summary_stats.tex`, and that path doesn't change when the
analysis code is reorganized.

Regenerate with `make analysis` (or `make model` for model artifacts). Hand-drawn /
illustrative figures that are *not* generated belong with their document instead (e.g.
`writing/paper/supp/figures/`).
