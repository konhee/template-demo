#!/usr/bin/env python3
"""fetch_fred.py — download all FRED series used by this project.

The `fetch` stage: pulls each series below from FRED's no-API-key CSV endpoint
into data/raw/fred/, one <series_id>.csv per series, plus a single PULLED_ON.txt
provenance stamp. Network-dependent, so it lives off the default Make graph
(`make fetch`).

To add a series, add one line to SERIES — nothing else changes.

Usage:
    python3 code/fetch/fetch_fred.py
"""
from __future__ import annotations

import urllib.request
from datetime import datetime, timezone
from pathlib import Path

# series id -> human-readable description (used in the provenance stamp).
SERIES = {
    "USAUCSFRCONDOSMSAMID": "Zillow Home Value Index, national (all homes, mid-tier, SA)",
    "CUSR0000SEHA": "CPI: Rent of Primary Residence (SA)",
    "CUSR0000SEHC": "CPI: Owners' Equivalent Rent of Residences (OER, SA)",
}

# FRED's public CSV endpoint — no API key required.
FRED_CSV = "https://fred.stlouisfed.org/graph/fredgraph.csv?id={series}"

PROJ_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = PROJ_ROOT / "data" / "raw"
RAW_FRED_DIR = RAW_DIR / "fred"   # FRED source folder; holds all FRED series
STAMP_FILE = RAW_FRED_DIR / "PULLED_ON.txt"


def main() -> None:
    RAW_FRED_DIR.mkdir(parents=True, exist_ok=True)

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    # Same field style as a hand-written stamp (see data/README.md), so an
    # auto-generated and a manual PULLED_ON.txt read the same.
    stamp_lines = [
        f"Pulled on : {now}\n"
        f"Source    : FRED public CSV endpoint (no API key), "
        f"https://fred.stlouisfed.org/graph/fredgraph.csv?id=<series>\n"
        f"By        : make fetch  (code/fetch/fetch_fred.py)\n"
        f"Files     : one <series_id>.csv per series listed below\n"
    ]

    for series, desc in SERIES.items():
        url = FRED_CSV.format(series=series)
        dest_file = RAW_FRED_DIR / f"{series}.csv"

        print(f">> downloading {url}")
        urllib.request.urlretrieve(url, dest_file)

        size = dest_file.stat().st_size
        print(f">> wrote {dest_file.relative_to(PROJ_ROOT)} ({size:,} bytes)")
        stamp_lines.append(
            f"\n{series}.csv — {desc}\n"
            f"    csv:  {url}\n"
            f"    page: https://fred.stlouisfed.org/series/{series}\n"
        )

    STAMP_FILE.write_text("".join(stamp_lines))


if __name__ == "__main__":
    main()
