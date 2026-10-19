#!/usr/bin/env python3
"""figures.py — visual samples of common chart types, in matplotlib.

PERMANENT REFERENCE. Not on the Make graph, not part of the project's analysis.
The Python companion to ../stata/figures.do and ../r/figures.R: draws the SAME
menu of chart types under a mono (grayscale) and a color (matplotlib default)
variant, so a Python-based analysis can match a Stata- or R-based one. Built
entirely from code/lib/py/mtcars.py (a literal copy of R's base `mtcars`, no
data/ dependency, no network) since Python has no built-in analogue of Stata's
`sysuse auto`/`uslifeexp` either — see README.md for the exact variable
substitutions used throughout (same ones ../r/figures.R uses, since both build
on the same mtcars values).

Needs, beyond pandas: matplotlib, scipy (kdensity charts only). Install once with:
    conda env update -f environment.yml   # or: pip install matplotlib scipy

Chart menu (function per chart; comment out a line in draw_all() to skip one):
    scatter      one group, structural marker
    timeseries   single line, top-left y-label, symmetric x ticks
    histogram    single distribution
    eventstudy   coefficients +/- 95% CI around an event, ref period pinned to 0
    coefplot     coefficients across specs, horizontal, CI whiskers
    bar          mean per category, single series
    binscatter   binned means by group (mono distinguishes groups by marker fill)
    kdensity     overlaid densities by group (mono: solid vs. dashed line)
    histogram_overlap  translucent histogram fill + density line, overlaid by group

Run it (off the Makefile — invoke by hand, from anywhere in the repo):
    python3 code/reference/py/figures.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import gaussian_kde

# --- locate the repo root, so paths work regardless of the working directory ----
# This file sits THREE levels below the root (code/reference/py/), matching the
# skeletons/analysis.py climb.
PROJ_ROOT = Path(__file__).resolve().parents[3]
FIG_DIR = PROJ_ROOT / "code" / "reference" / "py" / "output" / "figures"

sys.path.insert(0, str(PROJ_ROOT / "code" / "lib" / "py"))
import mtcars  # noqa: E402


# --- style — a mono/color pair. color uses matplotlib's own default rcParams
# (no override); mono switches to the "grayscale" built-in style.
# ==============================================================================
STYLES = ("mono", "color")


def figexport(fig, name: str, suffix: str) -> None:
    """Write PDF + wide PNG, tagging the filename with the mono/color suffix so
    both variants of a chart sort adjacent."""
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    stub = FIG_DIR / f"{name}_{suffix}"
    fig.savefig(f"{stub}.pdf")
    fig.savefig(f"{stub}.png", dpi=200)
    print(f">> wrote {stub}.pdf / .png")


# ==============================================================================
# scatter (single group). mtcars analogue of sysuse auto's mpg-vs-weight.
# ==============================================================================
def fig_scatter(suffix: str) -> None:
    df = mtcars.load()
    weight_lbs = df["wt"] * 1000

    fig, ax = plt.subplots()
    ax.scatter(weight_lbs, df["mpg"], s=60, marker="o")
    ax.set_title("Mileage (mpg)")
    ax.set_xlabel("Weight (lbs)")
    figexport(fig, "scatter", suffix)
    plt.close(fig)


# ==============================================================================
# time series (single line). No Python built-in analogue of sysuse uslifeexp
# exists, so this uses the same synthetic monotonic-concave curve ../r/figures.R
# uses (rising life expectancy that flattens over the century).
# ==============================================================================
def fig_timeseries(suffix: str) -> None:
    years = np.arange(1900, 2001, 5)
    le = 47 + 30 * (1 - np.exp(-(years - 1900) / 40))

    fig, ax = plt.subplots()
    ax.plot(years, le, linewidth=2.2)
    ax.set_title("Life expectancy (years)")
    ax.set_xlabel("Year")
    ax.set_xticks(np.arange(1900, 2001, 20))
    figexport(fig, "timeseries", suffix)
    plt.close(fig)


# ==============================================================================
# histogram (single distribution).
# ==============================================================================
def fig_histogram(suffix: str) -> None:
    df = mtcars.load()
    weights = np.full(len(df), 100 / len(df))  # each bar reads as percent of N

    fig, ax = plt.subplots()
    ax.hist(df["mpg"], bins=np.arange(df["mpg"].min() - 3, df["mpg"].max() + 3, 3),
            weights=weights)
    ax.set_title("Percent")
    ax.set_xlabel("Mileage (mpg)")
    figexport(fig, "histogram", suffix)
    plt.close(fig)


# ==============================================================================
# event study. Synthetic coefficients +/- 95% CI around an event at t=0, reference
# period t=-1 pinned to exactly 0 — same construction as ../stata/figures.do and
# ../r/figures.R.
# ==============================================================================
def fig_eventstudy(suffix: str) -> None:
    t = np.arange(-5, 6)
    coef = np.where(t < 0, 0.0, 0.15 * (t + 1))
    coef[t == -1] = 0.0
    se = np.where(t == -1, 0.0, 0.05 + 0.01 * np.abs(t))
    hi, lo = coef + 1.96 * se, coef - 1.96 * se

    fig, ax = plt.subplots()
    ax.fill_between(t, lo, hi, alpha=0.2)
    ax.plot(t, coef, linewidth=1.8)
    ax.scatter(t, coef, s=40, zorder=3)
    ax.axhline(0, color="black", linewidth=0.8)
    ax.axvline(0, color="black", linewidth=0.8)
    ax.set_xticks(t)
    ax.set_title("Coefficient (95% CI)")
    ax.set_xlabel("Event time")
    figexport(fig, "eventstudy", suffix)
    plt.close(fig)


# ==============================================================================
# coefficient plot. Synthetic coefficients across four specifications, horizontal,
# with 95% CI whiskers.
# ==============================================================================
def fig_coefplot(suffix: str) -> None:
    specs = ["Baseline", "+ Controls", "+ FE", "+ Cluster"]  # top -> bottom (y reversed below)
    coefs = np.array([0.35, 0.40, 0.45, 0.50])
    se = np.full(4, 0.06)
    hi, lo = coefs + 1.96 * se, coefs - 1.96 * se

    y = np.arange(len(specs))[::-1]  # Baseline at top, matching ../r/figures.R's render order

    fig, ax = plt.subplots()
    ax.errorbar(coefs, y, xerr=[coefs - lo, hi - coefs], fmt="none",
                ecolor="black", elinewidth=1.4, capsize=4)
    ax.scatter(coefs, y, s=60, zorder=3)
    ax.axvline(0, color="black", linewidth=0.8)
    ax.set_yticks(y, specs)
    ax.set_title("Specification")
    ax.set_xlabel("Coefficient (95% CI)")
    figexport(fig, "coefplot", suffix)
    plt.close(fig)


# ==============================================================================
# bar chart. Mean mpg by cylinder count — mtcars analogue of mean mpg by rep78.
# ==============================================================================
def fig_bar(suffix: str) -> None:
    df = mtcars.load()
    grouped = df.groupby("cyl")["mpg"].mean()

    fig, ax = plt.subplots()
    ax.bar([str(c) for c in grouped.index], grouped.values, width=0.6)
    ax.set_title("Mean mileage (mpg)")
    ax.set_xlabel("Cylinders")
    figexport(fig, "bar", suffix)
    plt.close(fig)


# ==============================================================================
# binned scatter by group. Manual quartile-bin-and-collapse (mtcars is far smaller
# than auto.dta, so quartiles stand in for deciles) within each `am` group
# (relabeled Automatic/Manual). mono tells the groups apart by marker fill (filled
# vs. hollow circle) since there is no color to lean on; color uses matplotlib's
# default categorical cycle.
# ==============================================================================
def fig_binscatter(suffix: str) -> None:
    df = mtcars.load().copy()
    df["group"] = df["am"].map({0: "Automatic", 1: "Manual"})
    labels = ["Automatic", "Manual"]
    fills = [True, False] if suffix == "mono" else [True, True]

    fig, ax = plt.subplots()
    for label, filled in zip(labels, fills):
        sub = df[df["group"] == label].copy()
        sub["bin"] = pd.qcut(sub["wt"], 4, labels=False)
        binned = sub.groupby("bin")[["wt", "mpg"]].mean()
        ax.scatter(binned["wt"], binned["mpg"], s=60, label=label,
                   facecolor=None if filled else "none", edgecolor=None, linewidth=1.4)
    ax.legend()
    ax.set_title("Mileage (mpg)")
    ax.set_xlabel("Weight (lbs, thousands)")
    figexport(fig, "binscatter", suffix)
    plt.close(fig)


# ==============================================================================
# kernel-density overlay by group. mono tells densities apart by linestyle (solid
# vs. dashed) since there is no color to lean on.
# ==============================================================================
def fig_kdensity(suffix: str) -> None:
    df = mtcars.load().copy()
    df["group"] = df["am"].map({0: "Automatic", 1: "Manual"})
    labels = ["Automatic", "Manual"]
    linestyles = ["solid", "dashed"] if suffix == "mono" else ["solid", "solid"]
    grid = np.linspace(df["mpg"].min() - 5, df["mpg"].max() + 5, 200)

    fig, ax = plt.subplots()
    for label, ls in zip(labels, linestyles):
        x = df.loc[df["group"] == label, "mpg"]
        density = gaussian_kde(x)(grid)
        ax.plot(grid, density, linestyle=ls, linewidth=1.8, label=label)
    ax.legend()
    ax.set_title("Density")
    ax.set_xlabel("Mileage (mpg)")
    figexport(fig, "kdensity", suffix)
    plt.close(fig)


# ==============================================================================
# histogram + kdensity overlay by group. Like fig_kdensity, but with translucent
# histogram fill shown behind each density line.
# ==============================================================================
def fig_histogram_overlap(suffix: str) -> None:
    df = mtcars.load().copy()
    df["group"] = df["am"].map({0: "Automatic", 1: "Manual"})
    bins = np.arange(df["mpg"].min() - 3, df["mpg"].max() + 3, 3)
    grid = np.linspace(df["mpg"].min() - 5, df["mpg"].max() + 5, 200)

    fig, ax = plt.subplots()
    for label in ["Automatic", "Manual"]:
        x = df.loc[df["group"] == label, "mpg"]
        ax.hist(x, bins=bins, density=True, histtype="stepfilled", alpha=0.3, label=label)
        density = gaussian_kde(x)(grid)
        ax.plot(grid, density, linewidth=1.8)
    ax.legend()
    ax.set_title("Density")
    ax.set_xlabel("Mileage (mpg)")
    figexport(fig, "histogram_overlap", suffix)
    plt.close(fig)


# --- draw_all — draw every chart under the given suffix. Comment out a line to
# skip that chart. Called once per suffix (mono, color).
# ==============================================================================
def draw_all(suffix: str) -> None:
    fig_scatter(suffix)
    fig_timeseries(suffix)
    fig_histogram(suffix)
    fig_eventstudy(suffix)
    fig_coefplot(suffix)
    fig_bar(suffix)
    fig_binscatter(suffix)
    fig_kdensity(suffix)
    fig_histogram_overlap(suffix)


# --- main — run the full chart menu per style: mono uses matplotlib's built-in
# "grayscale" style; color uses matplotlib's plain default. -------------------
def main() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    with plt.style.context("grayscale"):
        draw_all("mono")
        print(">> figures.py: mono -> output/figures/*_mono.pdf complete")

    draw_all("color")
    print(">> figures.py: color -> output/figures/*_color.pdf complete")
    print(">> figures.py complete")


if __name__ == "__main__":
    main()
