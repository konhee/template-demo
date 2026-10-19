# code/explore/

Exploratory, one-off analysis. **Nothing here is wired into the Makefile** — `make`
never runs it, so the reproducible pipeline stays clean.

One folder per line of inquiry. Suggested naming: `YYYY-MM-<short-slug>/`, e.g.
`2026-07-price-check/`. Inside each folder:

```
2026-07-price-check/
├── check.do          # or .py — the exploratory code
├── output/           # figures/tables you're iterating on — TRACKED
└── data/             # scratch intermediates — GITIGNORED (**/data/)
```

- Keep output **colocated** with the code that made it — an orphaned figure in a
  shared bin is unreadable six months later.
- `output/` is tracked so you keep history while iterating and coauthors can see
  results without rerunning. `data/` is scratch and stays out of git.
- To retire a dead end, delete the whole folder — its history remains in git.
- When an exploration earns a place in the paper, **promote** it: move the script to
  `code/analysis/` and point it at the top-level `output/`.
