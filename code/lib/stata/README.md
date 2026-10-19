# code/lib/stata — shared Stata environment

Everything every analysis/build `.do` file needs at startup: locating the repo
root, putting this directory on the ado path, and ensuring package dependencies
are present. Analysis scripts pull it all in with a short bootstrap (below);
the mechanics live here so individual scripts stay uncluttered.

## Files

- **`setup.do`** — locates the repo root, `cd`s there, adds `code/lib/stata` to
  the ado search path, and runs `dependencies.do`. Every pipeline `.do` sources
  it first.
- **`dependencies.do`** — Tier 2 dependency management (see below): installs
  third-party SSC/net packages we don't author (`binscatter`, `reghdfe`, …).
- **Other vendored `.ado` files** — Tier 1: code we author or pin lives here and
  is found automatically via the ado path.

## The bootstrap: how scripts find `setup.do`

Stata has no `__file__` — a running `.do` cannot know its own location on disk.
The only thing it knows is the current working directory (`cwd`). So a script
finds `setup.do` by relative path, and which relative path works depends on how
Stata was launched:

| Launch mode                         | cwd at start   | path to `setup.do`             |
| ----------------------------------- | -------------- | ------------------------------ |
| `make` (batch, logs to `.make/logs`)| `.make/logs/`  | `../../code/lib/stata/setup.do`|
| double-click a `.do` (file assoc.)  | `code/<stage>/`| `../lib/stata/setup.do`        |
| open Stata, then File ▸ Open        | **arbitrary**  | — (cannot be detected)         |

(Under `make`, the Makefile `cd`s into `.make/logs/` before launching Stata so the batch
log lands there — hence the two-level climb, not "repo root".)

Each pipeline script therefore probes all three deterministic locations, taking the
first that exists:

```stata
local setup "code/lib/stata/setup.do"              // cwd = repo root
capture confirm file "`setup'"
if _rc local setup "../lib/stata/setup.do"         // cwd = code/<stage>/ (double-click)
capture confirm file "`setup'"
if _rc local setup "../../code/lib/stata/setup.do" // cwd = .make/logs/ (make batch)
capture confirm file "`setup'"
if _rc {
    display as error "Could not find setup.do; cd to the repo root and rerun."
    exit 601
}
do "`setup'"
```

`confirm file` only tests existence, so probing leaves `cwd` untouched. Once one
resolves, `setup.do` climbs to the root and normalizes
`cwd`, so all downstream relative paths (`data/derived/...`, `output/...`) work.

**The File ▸ Open case cannot be auto-detected** — cwd is unrelated to the
project, and no cwd-based search can find the repo. Fix it with one manual step:
`cd "/path/to/your/template"` before running. (Or just double-click the file
instead, which sets cwd for you.) We deliberately do **not** hardcode machine
paths or require a per-machine setup file to avoid this; a single `cd` is the
price for the one launch mode that is impossible to detect.

## Dependency strategy — two tiers

**Tier 1 — vendor (committed).** Code we author or want to pin lives directly
in this directory and is committed. `setup.do` adds the directory to the ado
path, so Stata finds it by name with no network and no admin rights — the
portable default for locked-down machines.

**Tier 2 — install on demand.** Third-party packages we don't author
(`binscatter`, `reghdfe`, …) are listed in `dependencies.do`, which `ssc install`s
any that are missing and skips those already present. Add new packages to the
`required` list there. On an offline/locked-down machine where `ssc install`
fails, the fix is to *vendor* the package (promote it to Tier 1): copy its
`.ado`/`.sthlp` files into this directory and commit them.
