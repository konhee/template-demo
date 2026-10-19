# writing/notebook/

The **informal front** of the writing lifecycle: a running record of the project as it
develops — meeting logs, scattered thoughts, early ideas for where things should go —
before any of it is cleaned up and promoted into a compiled document.

**Tracked in git, but the opposite of `temp/`.** `temp/` is disposable scratch that git
ignores; this is kept. These notes are the raw material a finished write-up grows out of,
so they belong in history.

## Promotion

`notebook/` is the rough end of `writing/`; the compiled documents are the polished end.
As a note firms up, promote it:

```
notebook/  →  notes/  →  paper/   (slides/ is a presentation cut of paper/)
```

This mirrors the `code/explore/ → code/analysis/` path on the code side: a sandbox for
half-formed work, graduating into the built pipeline once it matures.

## Conventions

- **Any format.** Mostly `.md` / `.txt`, but whatever the thought arrived in is fine —
  including PDFs or photos/scans of handwritten (iPad) pages. Binary files track as opaque
  blobs (like the figures in `output/` or the papers in `references/literature/`); they
  won't show a readable diff, so let the **filename** carry the context.
- **Date-prefix filenames** — `YYYY-MM-DD-topic.md` — so things sort chronologically and a
  non-diffable scan is still identifiable at a glance.
- **No imposed structure.** Keep it a flat dumping ground; don't build a `meetings/` /
  `ideas/` taxonomy. Informal notes stop getting written the moment they need filing. If it
  ever genuinely overflows, subfolder by topic then — same flat-until-it-hurts rule the code
  stages follow.

## Not built

`make` never touches this directory — `make docs` / `paper` / `slides` / `notes` compile
named documents, not everything under `writing/`. Nothing here needs to compile.
