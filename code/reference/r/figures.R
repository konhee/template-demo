#!/usr/bin/env Rscript
# figures.R — visual samples of common chart types, in ggplot2.
#
# PERMANENT REFERENCE. Not on the Make graph, not part of the project's analysis.
# The R companion to ../stata/figures.do: draws the SAME menu of chart types
# under a mono (grayscale) and a color (ggplot2 default) variant, so an
# R-based analysis can match a Stata-based one. Built entirely from base R's
# `mtcars` (no data/ dependency, no network) since R has no built-in analogue
# of Stata's `sysuse auto`/`uslifeexp` — see README.md for the exact variable
# substitutions used throughout (mpg -> mpg, wt*1000 -> weight in lbs,
# cyl -> rep78-style category, am -> a two-group split standing in for foreign).
#
# R is BEST-EFFORT in this template (see README.md) — this script needs, beyond
# base R: ggplot2, dplyr, scales. Install once with:
#     install.packages(c("ggplot2", "dplyr", "scales"))
#
# Chart menu (function per chart; comment out a line in draw_all() to skip one):
#   scatter      one group, structural marker
#   timeseries   single line, top-left y-label, symmetric x ticks
#   histogram    single distribution
#   eventstudy   coefficients +/- 95% CI around an event, ref period pinned to 0
#   coefplot     coefficients across specs, horizontal, CI whiskers
#   bar          mean per category, single series
#   binscatter   binned means by group (mono distinguishes groups by marker shape)
#   kdensity     overlaid densities by group
#   histogram_overlap  translucent histogram fill + density line, overlaid by group
#
# Run it (off the Makefile — invoke by hand, from anywhere in the repo):
#     Rscript code/reference/r/figures.R

# --- locate the repo root, so paths work regardless of the working directory ----
# This file sits THREE levels below the root (code/reference/r/), matching the
# skeletons/analysis.R climb.
this_file <- sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))
proj_root <- normalizePath(file.path(dirname(this_file), "..", "..", ".."))
fig_dir   <- file.path(proj_root, "code", "reference", "r", "output", "figures")

required_pkgs <- c("ggplot2", "dplyr", "scales")
missing_pkgs <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  stop(sprintf(
    "Missing required package(s): %s. Install with install.packages(c(%s)).",
    paste(missing_pkgs, collapse = ", "),
    paste(sprintf('"%s"', missing_pkgs), collapse = ", ")
  ))
}
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(scales)
})

# --- init — create the output dir (this file's own tracked output/figures/,
# colocated with the code that made it, mirroring the Stata reference layout).
# ==============================================================================
init <- function() {
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
}

# --- figexport — write PDF + wide PNG, tagging the filename with the mono/color
# suffix so both variants of a chart sort adjacent.
# ==============================================================================
figexport <- function(plot, name, suffix, width_in = 6, height_in = 4.5) {
  stub <- file.path(fig_dir, paste0(name, "_", suffix))
  ggsave(paste0(stub, ".pdf"), plot, width = width_in, height = height_in, units = "in")
  ggsave(paste0(stub, ".png"), plot, width = width_in, height = height_in, units = "in", dpi = 200)
  cat(sprintf(">> wrote %s.pdf / .png\n", stub))
}

# ==============================================================================
# scatter (single group). mtcars analogue of sysuse auto's mpg-vs-weight.
# ==============================================================================
fig_scatter <- function(suffix) {
  df <- mtcars |> mutate(weight_lbs = wt * 1000)

  p <- ggplot(df, aes(x = weight_lbs, y = mpg)) +
    geom_point(size = 3) +
    scale_x_continuous(labels = comma) +
    labs(title = "Mileage (mpg)", x = "Weight (lbs)", y = NULL)
  figexport(p, "scatter", suffix)
}

# ==============================================================================
# time series (single line). No base-R analogue of sysuse uslifeexp exists, so this
# uses a synthetic monotonic-concave curve with the same shape (rising life
# expectancy that flattens over the century).
# ==============================================================================
fig_timeseries <- function(suffix) {
  years <- seq(1900, 2000, by = 5)
  df <- data.frame(year = years, le = 47 + 30 * (1 - exp(-(years - 1900) / 40)))

  p <- ggplot(df, aes(x = year, y = le)) +
    geom_line(linewidth = 0.9) +
    scale_x_continuous(breaks = seq(1900, 2000, by = 20)) +
    labs(title = "Life expectancy (years)", x = "Year", y = NULL)
  figexport(p, "timeseries", suffix)
}

# ==============================================================================
# histogram (single distribution).
# ==============================================================================
fig_histogram <- function(suffix) {
  p <- ggplot(mtcars, aes(x = mpg)) +
    geom_histogram(aes(y = after_stat(count) / sum(after_stat(count)) * 100),
                    binwidth = 3, boundary = 0) +
    labs(title = "Percent", x = "Mileage (mpg)", y = NULL)
  figexport(p, "histogram", suffix)
}

# ==============================================================================
# event study. Synthetic coefficients +/- 95% CI around an event at t=0, reference
# period t=-1 pinned to exactly 0 — same construction as ../stata/figures.do.
# ==============================================================================
fig_eventstudy <- function(suffix) {
  t <- -5:5
  coef <- ifelse(t < 0, 0, 0.15 * (t + 1))
  coef[t == -1] <- 0
  se <- ifelse(t == -1, 0, 0.05 + 0.01 * abs(t))
  df <- data.frame(t = t, coef = coef, hi = coef + 1.96 * se, lo = coef - 1.96 * se)

  p <- ggplot(df, aes(x = t)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2) +
    geom_line(aes(y = coef), linewidth = 0.8) +
    geom_point(aes(y = coef), size = 2) +
    geom_hline(yintercept = 0, colour = "black", linewidth = 0.4) +
    geom_vline(xintercept = 0, colour = "black", linewidth = 0.4) +
    scale_x_continuous(breaks = t) +
    labs(title = "Coefficient (95% CI)", x = "Event time", y = NULL)
  figexport(p, "eventstudy", suffix)
}

# ==============================================================================
# coefficient plot. Synthetic coefficients across four specifications, horizontal,
# with 95% CI whiskers — built via coord_flip() rather than geom_errorbarh() (kept
# off ggplot2's deprecated horizontal-geom family).
# ==============================================================================
fig_coefplot <- function(suffix) {
  spec_levels <- c("+ Cluster", "+ FE", "+ Controls", "Baseline") # bottom -> top after flip
  df <- data.frame(
    spec = factor(c("Baseline", "+ Controls", "+ FE", "+ Cluster"), levels = spec_levels),
    coef = c(.35, .40, .45, .50),
    se   = rep(.06, 4)
  ) |> mutate(hi = coef + 1.96 * se, lo = coef - 1.96 * se)

  p <- ggplot(df, aes(x = spec, y = coef)) +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.15, linewidth = 0.6) +
    geom_point(size = 3) +
    geom_hline(yintercept = 0, colour = "black", linewidth = 0.4) +
    coord_flip() +
    labs(title = "Specification", x = NULL, y = "Coefficient (95% CI)")
  figexport(p, "coefplot", suffix)
}

# ==============================================================================
# bar chart. Mean mpg by cylinder count — mtcars analogue of mean mpg by rep78.
# ==============================================================================
fig_bar <- function(suffix) {
  df <- mtcars |> group_by(cyl) |> summarise(mpg = mean(mpg), .groups = "drop")

  p <- ggplot(df, aes(x = factor(cyl), y = mpg)) +
    geom_col(width = 0.8) +
    labs(title = "Mean mileage (mpg)", x = "Cylinders", y = NULL)
  figexport(p, "bar", suffix)
}

# ==============================================================================
# binned scatter by group. Manual quartile-bin-and-collapse (mtcars is far smaller
# than auto.dta, so quartiles stand in for deciles) within each `am` group (relabeled
# Automatic/Manual — this script's stand-in two-group split). mono tells the groups
# apart by marker shape (filled vs. open circle) since there is no color to lean on.
# ==============================================================================
fig_binscatter <- function(suffix) {
  df <- mtcars |>
    mutate(group = factor(am, levels = c(0, 1), labels = c("Automatic", "Manual"))) |>
    group_by(group) |>
    mutate(bin = ntile(wt, 4)) |>
    group_by(group, bin) |>
    summarise(mpg = mean(mpg), wt = mean(wt), .groups = "drop")

  p <- ggplot(df, aes(x = wt, y = mpg, colour = group, shape = group)) +
    geom_point(size = 3) +
    labs(title = "Mileage (mpg)", x = "Weight (lbs, thousands)", y = NULL)
  if (suffix == "mono") {
    p <- p + scale_colour_grey() + scale_shape_manual(values = c(19, 1))
  }
  figexport(p, "binscatter", suffix)
}

# ==============================================================================
# kernel-density overlay by group. mono tells densities apart by linetype (solid vs.
# dashed) since there is no color to lean on.
# ==============================================================================
fig_kdensity <- function(suffix) {
  df <- mtcars |> mutate(group = factor(am, levels = c(0, 1), labels = c("Automatic", "Manual")))

  p <- ggplot(df, aes(x = mpg, colour = group, linetype = group)) +
    stat_density(geom = "line", linewidth = 0.8) + # not geom_density(): that's
    # built on GeomArea, so its legend key renders as a box; a plain line
    # segment key matches this chart's dashed/solid distinction better.
    labs(title = "Density", x = "Mileage (mpg)", y = NULL)
  if (suffix == "mono") {
    p <- p + scale_colour_grey() + scale_linetype_manual(values = c("solid", "dashed"))
  }
  figexport(p, "kdensity", suffix)
}

# ==============================================================================
# histogram + kdensity overlay by group. Like fig_kdensity, but with translucent
# histogram fill shown behind each density line.
# ==============================================================================
fig_histogram_overlap <- function(suffix) {
  df <- mtcars |> mutate(group = factor(am, levels = c(0, 1), labels = c("Automatic", "Manual")))

  p <- ggplot(df, aes(x = mpg)) +
    geom_histogram(aes(y = after_stat(density), fill = group, colour = group), binwidth = 3,
                    boundary = 0, position = "identity", alpha = 0.3) +
    geom_density(aes(colour = group), linewidth = 0.8, show.legend = FALSE) +
    labs(title = "Density", x = "Mileage (mpg)", y = NULL)
  if (suffix == "mono") {
    p <- p + scale_fill_grey() + scale_colour_grey()
  }
  figexport(p, "histogram_overlap", suffix)
}

# --- draw_all — draw every chart under the given suffix. Comment out a line to
# skip that chart. Called once per suffix (mono, color).
# ==============================================================================
draw_all <- function(suffix) {
  fig_scatter(suffix)
  fig_timeseries(suffix)
  fig_histogram(suffix)
  fig_eventstudy(suffix)
  fig_coefplot(suffix)
  fig_bar(suffix)
  fig_binscatter(suffix)
  fig_kdensity(suffix)
  fig_histogram_overlap(suffix)
}

# --- main — run the full chart menu per style: mono uses theme_grey()'s
# built-in grayscale look via scale_*_grey() per chart; color is ggplot2's
# plain default. ---------------------------------------------------------------
main <- function() {
  init()

  for (suffix in c("mono", "color")) {
    draw_all(suffix)
    cat(sprintf(">> figures.R: %s -> output/figures/*_%s.pdf complete\n", suffix, suffix))
  }
  cat(">> figures.R complete\n")
}

main()
