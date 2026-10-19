#!/usr/bin/env python3
"""analysis.py — SKELETON for a Python pipeline script. Copy this to start.

PERMANENT REFERENCE. Not on the Make graph. This is the canonical shape every
build/analysis Python script follows: a module docstring naming inputs/outputs, a
root-anchored set of path constants, a `main()` doing the work, and the
`if __name__ == "__main__"` guard. It runs as-is (writes one tiny CSV under this
folder's output/, no data/ needed) so you can execute it once to see the pattern,
then swap in your real read/transform/write.

The conventions this demonstrates (keep them when you copy):
    - PROJ_ROOT computed from __file__, so paths work from any working directory.
    - All I/O paths as constants up top, anchored at PROJ_ROOT — never relative to
      the cwd, never hardcoded absolute.
    - main() reads only from data/raw or data/derived, writes only to its own output.
    - mkdir(parents=True, exist_ok=True) before writing; print what was written.

Output: code/reference/skeletons/output/skeleton.csv

Usage:
    python3 code/reference/skeletons/analysis.py
"""
from __future__ import annotations

from pathlib import Path

import pandas as pd

# parents[3] because this file sits three levels below the repo root
# (code/reference/skeletons/). A real script in code/build/ or code/analysis/ is
# TWO levels below, so it uses parents[2] — match the index to where you copy this.
PROJ_ROOT = Path(__file__).resolve().parents[3]
OUT_DIR = PROJ_ROOT / "code" / "reference" / "skeletons" / "output"
OUT_FILE = OUT_DIR / "skeleton.csv"
# A real script would also anchor its inputs here, pointing at the producer
# namespace it reads, e.g.:
#   DERIVED_DIR = PROJ_ROOT / "data" / "derived" / "build"


def main() -> None:
    # Read -> transform -> write. Here the "read" is a stand-in literal; a real
    # script would read a raw/derived file with pd.read_csv(DERIVED_DIR / "...").
    df = build_demo_frame()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUT_FILE, index=False)

    print(f">> wrote {OUT_FILE.relative_to(PROJ_ROOT)}: {len(df)} rows")


def build_demo_frame() -> pd.DataFrame:
    """Stand in for the real read + transform step (one helper per logical step)."""
    return pd.DataFrame({"x": [1, 2, 3], "x_squared": [1, 4, 9]})


if __name__ == "__main__":
    main()
