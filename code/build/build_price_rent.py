#!/usr/bin/env python3
"""build_price_rent.py — merge FRED series into an annual price/rent panel.

The `build` stage: reads the three raw FRED series (national ZHVI + two BLS CPI
rent indices), collapses each from monthly to a calendar-year mean, and merges
them into one tidy annual panel. Reads only from data/raw/, writes only to
its own producer namespace data/derived/build/.

Output: data/derived/build/price_rent_annual.csv
    year          calendar year
    zhvi          Zillow Home Value Index, annual mean (level, $)
    rent_primary  CPI Rent of Primary Residence, annual mean (index)
    oer           CPI Owners' Equivalent Rent, annual mean (index)

Only years with 12 monthly observations are kept, so a partial current year is dropped.

Usage:
    python3 code/build/build_price_rent.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

PROJ_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = PROJ_ROOT / "data" / "raw"
RAW_FRED_DIR = RAW_DIR / "fred"   # input: the raw FRED series
# The build stage writes into its own producer namespace under data/derived/.
DERIVED_DIR = PROJ_ROOT / "data" / "derived" / "build"
DERIVED_FILE = DERIVED_DIR / "price_rent_annual.csv"

# FRED series id -> tidy column name in the output panel.
SERIES = {
    "USAUCSFRCONDOSMSAMID": "zhvi",
    "CUSR0000SEHA": "rent_primary",
    "CUSR0000SEHC": "oer",
}


def main() -> None:
    panel: pd.DataFrame | None = None
    for series_id, col in SERIES.items():
        annual = annual_mean(series_id, col)
        panel = annual if panel is None else panel.merge(annual, on="year", how="inner")

    panel = panel.sort_values("year").reset_index(drop=True)

    DERIVED_DIR.mkdir(parents=True, exist_ok=True)
    panel.to_csv(DERIVED_FILE, index=False)

    print(f">> wrote {DERIVED_FILE.relative_to(PROJ_ROOT)}: "
          f"{len(panel)} years, {int(panel['year'].min())}–{int(panel['year'].max())}")


def annual_mean(series_id: str, col: str) -> pd.DataFrame:
    """Load one FRED CSV and collapse to a complete-year annual mean."""
    path = RAW_FRED_DIR / f"{series_id}.csv"
    if not path.exists():
        print(f"!! missing {path.relative_to(PROJ_ROOT)} — run `make fetch` first.",
              file=sys.stderr)
        sys.exit(1)

    # FRED CSVs are: observation_date, <SERIES_ID>
    df = pd.read_csv(path, parse_dates=["observation_date"])
    df = df.rename(columns={"observation_date": "date", series_id: col})
    df[col] = pd.to_numeric(df[col], errors="coerce")
    df = df.dropna(subset=[col])
    df["year"] = df["date"].dt.year

    # Keep only complete years (12 monthly observations) so annual means are
    # comparable across years and the partial current year drops out.
    counts = df.groupby("year")[col].transform("size")
    df = df[counts == 12]

    return df.groupby("year", as_index=False)[col].mean()


if __name__ == "__main__":
    main()
