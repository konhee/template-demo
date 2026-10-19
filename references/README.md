# references/

**Collected** reference material — external documents you consult, not documents you
author. `make` never touches this directory and nothing `\input`s it. (The documents you
*write* live in the top-level `writing/`.)

```
references/
├── data-dictionaries/   # codebooks, variable definitions, data documentation
└── literature/          # related papers (PDFs)
```

Both subdirectories are **tracked** in git:

- **`data-dictionaries/`** — small, textual, and part of your data provenance; version
  them alongside the code that relies on those variable definitions.
- **`literature/`** — a handful of core related papers, kept with the repo so coauthors
  get the exact reading set. Fine for a few PDFs; if it ever balloons into dozens of
  large files, consider gitignoring this folder and letting `writing/references.bib` be
  the tracked record of *what* the literature is.
