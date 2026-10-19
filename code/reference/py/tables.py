#!/usr/bin/env python3
"""tables.py — samples of the house table style, in Python.

PERMANENT REFERENCE. Not on the Make graph, not part of the project's analysis.
The Python companion to ../stata/tables.do and ../r/tables.R: builds one table of
each kind, from code/lib/py/mtcars.py (no data/ dependency, no network — see
README.md for the exact variable substitutions used throughout, mirroring
figures.py), and writes each as a .tex fragment into this folder's tracked
output/tables/ — structurally parallel to the Stata esttab fragments (same
\\doublerule / \\midrule shape, same \\sym{} significance stars), so this file
doubles as the copy-paste reference for the house table look in Python.

This is the table companion to figures.py (matplotlib theme) in this folder.

Needs, beyond pandas: statsmodels (OLS), scipy (t-test). Install once with:
    conda env update -f environment.yml   # or: pip install statsmodels scipy

Table menu (function per table; comment out a line in main() to skip one):
    summary      descriptive stats: mean / sd / min / max / N
    correlation  pairwise correlation matrix
    regression   nested OLS specs with stars, SEs, r2/N
    balance      two-group means, difference, significance (t-test)

Run it (off the Makefile — invoke by hand, from anywhere in the repo):
    python3 code/reference/py/tables.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
from scipy.stats import ttest_ind

# --- locate the repo root, so paths work regardless of the working directory ----
PROJ_ROOT = Path(__file__).resolve().parents[3]
TAB_DIR = PROJ_ROOT / "code" / "reference" / "py" / "output" / "tables"

sys.path.insert(0, str(PROJ_ROOT / "code" / "lib" / "py"))
import mtcars  # noqa: E402


# --- init — create the output dir (this file's own tracked output/tables/). -----
# ==============================================================================
def init() -> None:
    TAB_DIR.mkdir(parents=True, exist_ok=True)


# --- stars — the house significance convention: * 0.10 ** 0.05 *** 0.01, wrapped
# in \sym{} to match the esttab-produced fragments in ../stata/output/tables/.
# ==============================================================================
def stars(p: float) -> str:
    if p < 0.01:
        return r"\sym{***}"
    if p < 0.05:
        return r"\sym{**}"
    if p < 0.10:
        return r"\sym{*}"
    return ""


# --- pad/padl — right/left-justify a string to a fixed width (cosmetic only: a
# tabular's columns align regardless of padding, but this keeps the raw .tex
# fragment readable, matching the fixed-width look of the esttab output it mirrors).
# ==============================================================================
def pad(x: str, width: int = 9) -> str:
    return str(x).rjust(width)


def padl(x: str, width: int = 16) -> str:
    return str(x).ljust(width)


# --- wrap_house_table — assemble a full tabular from a header row, body rows, and
# optional stats rows, using the SAME shape every ../stata/tables.do fragment
# shares: \doublerule at the top, \midrule under the header, \midrule before any
# stats block, \midrule to close. See README.md for why all four Stata table
# types reduce to this one shape.
# ==============================================================================
def wrap_house_table(ncol: int, header: str, body: list[str], stats: list[str] | None = None) -> str:
    lines = [rf"\begin{{tabular}}{{l*{{{ncol}}}{{c}}}}", r"\doublerule", header, r"\midrule", *body]
    if stats is not None:
        lines += [r"\midrule", *stats]
    lines += [r"\midrule", r"\end{tabular}"]
    return "\n".join(lines)


def write_table(tex: str, name: str) -> None:
    out_file = TAB_DIR / f"{name}.tex"
    out_file.write_text(tex + "\n")
    print(f">> wrote {out_file}")


# ==============================================================================
# summary — descriptive statistics: mean / sd / min / max / N, one row per var.
# Analogue of tab_summary in ../stata/tables.do (there: price/mpg/weight/length;
# here: mpg/hp/wt/qsec, see README.md for the mtcars substitution).
# ==============================================================================
def tab_summary() -> None:
    df = mtcars.load()
    varlabels = {"mpg": "Mileage (mpg)", "hp": "Horsepower", "wt": "Weight (1000 lbs)",
                 "qsec": "1/4 mile time (s)"}

    rows = []
    for v, label in varlabels.items():
        x = df[v]
        rows.append(
            f"{padl(label)}&{pad(f'{x.mean():.2f}')}&{pad(f'{x.std():.2f}')}&"
            f"{pad(f'{x.min():.0f}')}&{pad(f'{x.max():.0f}')}&{pad(len(x))}\\\\"
        )

    header = f"{padl('')}&{pad('Mean')}&{pad('SD')}&{pad('Min')}&{pad('Max')}&{pad('N')}\\\\"
    tex = wrap_house_table(5, header, rows)
    write_table(tex, "summary")


# ==============================================================================
# correlation — pairwise Pearson correlation matrix (lower triangle). Analogue of
# tab_correlation: not/nostar (no stars, no t-stats), lower-triangle only.
# ==============================================================================
def tab_correlation() -> None:
    df = mtcars.load()
    varlabels = {"mpg": "Mileage", "hp": "Horsepower", "wt": "Weight", "qsec": "1/4 mile"}
    m = df[list(varlabels)].corr()

    header = "&" + " & ".join(varlabels.values()) + r" \\"
    rows = []
    for i, vi in enumerate(varlabels):
        cells = [pad(f"{m.loc[vi, vj]:.3f}") if j <= i else "" for j, vj in enumerate(varlabels)]
        rows.append(f"{padl(varlabels[vi])}&" + "&".join(cells) + "\\\\")

    tex = wrap_house_table(len(varlabels), header, rows)
    write_table(tex, "correlation")


# ==============================================================================
# regression — the workhorse econ table: nested OLS specs side by side, stars,
# SEs below in parentheses, r2/N at the foot. Analogue of tab_regression (there:
# price on weight/mpg/foreign; here: hp on wt/qsec/am — horsepower as the
# continuous outcome, see README.md).
# ==============================================================================
def tab_regression() -> None:
    df = mtcars.load()
    specs = ["hp ~ wt", "hp ~ wt + qsec", "hp ~ wt + qsec + am"]
    models = [smf.ols(spec, data=df).fit() for spec in specs]
    coeflabels = {"wt": "Weight (1000 lbs)", "qsec": "1/4 mile time (s)", "am": "Manual"}

    header = f"{padl('')}&" + "&".join(pad(rf"\multicolumn{{1}}{{c}}{{({i + 1})}}")
                                        for i in range(len(models))) + "\\\\"

    body = []
    for v, label in coeflabels.items():
        est_cells, se_cells = [], []
        for m in models:
            if v in m.params.index:
                est_cells.append(pad(f"{m.params[v]:.3f}{stars(m.pvalues[v])}"))
                se_cells.append(pad(f"({m.bse[v]:.3f})"))
            else:
                est_cells.append(pad(""))
                se_cells.append(pad(""))
        body.append(f"{padl(label)}&" + "&".join(est_cells) + "\\\\")
        body.append(f"{padl('')}&" + "&".join(se_cells) + "\\\\")

    r2_cells = [pad(f"{m.rsquared:.3f}") for m in models]
    n_cells = [pad(f"{int(m.nobs)}") for m in models]
    stats = [
        f"{padl('R-squared')}&" + "&".join(r2_cells) + "\\\\",
        f"{padl('Observations')}&" + "&".join(n_cells) + "\\\\",
    ]

    tex = wrap_house_table(len(models), header, body, stats)
    write_table(tex, "regression")


# ==============================================================================
# balance — two-group comparison: mean of each variable by group, the difference,
# and its significance. Analogue of tab_balance (there: by foreign; here: by am,
# relabeled Automatic/Manual — see README.md).
# ==============================================================================
def tab_balance() -> None:
    df = mtcars.load()
    varlabels = {"mpg": "Mileage (mpg)", "hp": "Horsepower", "wt": "Weight (1000 lbs)"}
    header = f"{padl('')}&{pad('Automatic')}&{pad('Manual')}&{pad('Diff.', 16)}&{pad('t')}\\\\"

    rows = []
    for v, label in varlabels.items():
        x0 = df.loc[df["am"] == 0, v]
        x1 = df.loc[df["am"] == 1, v]
        tstat, pvalue = ttest_ind(x0, x1, equal_var=False)  # matches R's t.test() default (Welch)
        diff_cell = f"{x0.mean() - x1.mean():.1f}{stars(pvalue)}"
        rows.append(
            f"{padl(label)}&{pad(f'{x0.mean():.1f}')}&{pad(f'{x1.mean():.1f}')}&"
            f"{pad(diff_cell, 16)}&{pad(f'({tstat:.2f})')}\\\\"
        )

    tex = wrap_house_table(4, header, rows)
    write_table(tex, "balance")


# --- main — build every table. Comment out a line to skip that table. -----------
def main() -> None:
    init()
    tab_summary()
    tab_correlation()
    tab_regression()
    tab_balance()
    print(">> tables.py complete")


if __name__ == "__main__":
    main()
