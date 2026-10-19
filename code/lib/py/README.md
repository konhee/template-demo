# code/lib/py — shared Python helpers

## Files

- **`mtcars.py`** — the classic `mtcars` dataset as a literal dict (`load()` returns a
  `pandas.DataFrame`), since Python has no built-in equivalent (unlike base R). Sourced
  once via `statsmodels.datasets.get_rdataset` and hardcoded, so it's network-free at
  run time. Used by `../../reference/py/figures.py` and `tables.py`.

## How a script pulls this in

Python has no ado-path equivalent — Stata's `setup.do` puts `code/lib/stata/` on the ado
path so vendored files are found by name; Python scripts instead put `code/lib/py/` on
`sys.path` and import explicitly, after computing `PROJ_ROOT` the same way
`code/reference/skeletons/analysis.py` does:

```python
import sys
from pathlib import Path

PROJ_ROOT = Path(__file__).resolve().parents[3]  # match the climb to wherever you copy this
sys.path.insert(0, str(PROJ_ROOT / "code" / "lib" / "py"))
import mtcars
```

Requires `pandas` (already a required dependency) — see `environment.yml`.
