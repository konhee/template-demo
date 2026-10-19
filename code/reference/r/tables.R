#!/usr/bin/env Rscript
# tables.R — samples of the house table style, in R.
#
# PERMANENT REFERENCE. Not on the Make graph, not part of the project's analysis.
# The R companion to ../stata/tables.do: builds one table of each kind, from base
# R's `mtcars` (no data/ dependency, no network — see README.md for the exact
# variable substitutions used throughout, mirroring figures.R), and writes each as
# a .tex fragment into this folder's tracked output/tables/ — structurally parallel
# to the Stata esttab fragments (same \doublerule / \midrule shape, same \sym{}
# significance stars), so this file doubles as the copy-paste reference for the
# house table look in R.
#
# This is the table companion to figures.R (ggplot2 theme) in this folder.
#
# R is BEST-EFFORT in this template — this script needs, beyond base
# R: dplyr, broom. Install once with:
#     install.packages(c("dplyr", "broom"))
#
# Table menu (function per table; comment out a line in main() to skip one):
#   summary      descriptive stats: mean / sd / min / max / N
#   correlation  pairwise correlation matrix
#   regression   nested OLS specs with stars, SEs, r2/N
#   balance      two-group means, difference, significance (t-test)
#
# Run it (off the Makefile — invoke by hand, from anywhere in the repo):
#     Rscript code/reference/r/tables.R

# --- locate the repo root, so paths work regardless of the working directory ----
this_file <- sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))
proj_root <- normalizePath(file.path(dirname(this_file), "..", "..", ".."))
tab_dir   <- file.path(proj_root, "code", "reference", "r", "output", "tables")

required_pkgs <- c("dplyr", "broom")
missing_pkgs <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  stop(sprintf(
    "Missing required package(s): %s. Install with install.packages(c(%s)).",
    paste(missing_pkgs, collapse = ", "),
    paste(sprintf('"%s"', missing_pkgs), collapse = ", ")
  ))
}
suppressPackageStartupMessages({
  library(dplyr)
  library(broom)
})

# --- init — create the output dir (this file's own tracked output/tables/). -----
# ==============================================================================
init <- function() {
  dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
}

# --- stars — the house significance convention: * 0.10 ** 0.05 *** 0.01, wrapped
# in \sym{} to match the esttab-produced fragments in ../stata/output/tables/.
# ==============================================================================
stars <- function(p) {
  dplyr::case_when(
    p < 0.01 ~ "\\sym{***}",
    p < 0.05 ~ "\\sym{**}",
    p < 0.10 ~ "\\sym{*}",
    TRUE     ~ ""
  )
}

# --- pad — right-justify a string to a fixed width (cosmetic only: a tabular's
# columns align regardless of padding, but this keeps the raw .tex fragment
# readable, matching the fixed-width look of the esttab output it mirrors).
# ==============================================================================
pad <- function(x, width = 9) formatC(x, width = width)
padl <- function(x, width = 16) formatC(x, width = -width)

# --- wrap_house_table — assemble a full tabular from a header row, body rows, and
# optional stats rows, using the SAME shape every ../stata/tables.do fragment
# shares: \doublerule at the top, \midrule under the header, \midrule before any
# stats block, \midrule to close. See README.md for why all four Stata table
# types reduce to this one shape.
# ==============================================================================
wrap_house_table <- function(ncol, header, body, stats = NULL) {
  lines <- c(
    sprintf("\\begin{tabular}{l*{%d}{c}}", ncol),
    "\\doublerule",
    header,
    "\\midrule",
    body
  )
  if (!is.null(stats)) {
    lines <- c(lines, "\\midrule", stats)
  }
  lines <- c(lines, "\\midrule", "\\end{tabular}")
  paste(lines, collapse = "\n")
}

write_table <- function(tex, name) {
  out_file <- file.path(tab_dir, paste0(name, ".tex"))
  writeLines(tex, out_file)
  cat(sprintf(">> wrote %s\n", out_file))
}

# ==============================================================================
# summary — descriptive statistics: mean / sd / min / max / N, one row per var.
# Analogue of tab_summary in ../stata/tables.do (there: price/mpg/weight/length;
# here: mpg/hp/wt/qsec, see README.md for the mtcars substitution).
# ==============================================================================
tab_summary <- function() {
  vars <- c(mpg = "Mileage (mpg)", hp = "Horsepower", wt = "Weight (1000 lbs)",
             qsec = "1/4 mile time (s)")

  rows <- vapply(names(vars), function(v) {
    x <- mtcars[[v]]
    paste0(
      padl(vars[[v]]), "&", pad(sprintf("%.2f", mean(x))), "&",
      pad(sprintf("%.2f", sd(x))), "&", pad(sprintf("%.0f", min(x))), "&",
      pad(sprintf("%.0f", max(x))), "&", pad(length(x)), "\\\\"
    )
  }, character(1))

  header <- paste0(padl(""), "&", pad("Mean"), "&", pad("SD"), "&", pad("Min"),
                     "&", pad("Max"), "&", pad("N"), "\\\\")
  tex <- wrap_house_table(5, header, rows)
  write_table(tex, "summary")
}

# ==============================================================================
# correlation — pairwise Pearson correlation matrix (lower triangle). Analogue of
# tab_correlation: not/nostar (no stars, no t-stats), lower-triangle only.
# ==============================================================================
tab_correlation <- function() {
  vars <- c(mpg = "Mileage", hp = "Horsepower", wt = "Weight", qsec = "1/4 mile")
  m <- cor(mtcars[names(vars)])

  header <- paste0("&", paste(vars, collapse = " & "), " \\\\")
  rows <- vapply(seq_along(vars), function(i) {
    cells <- vapply(seq_along(vars), function(j) {
      if (j > i) "" else pad(sprintf("%.3f", m[i, j]))
    }, character(1))
    paste0(padl(vars[[i]]), "&", paste(cells, collapse = "&"), "\\\\")
  }, character(1))

  tex <- wrap_house_table(length(vars), header, rows)
  write_table(tex, "correlation")
}

# ==============================================================================
# regression — the workhorse econ table: nested OLS specs side by side, stars,
# SEs below in parentheses, r2/N at the foot. Analogue of tab_regression (there:
# price on weight/mpg/foreign; here: hp on wt/qsec/am — horsepower as the
# continuous outcome, see README.md).
# ==============================================================================
tab_regression <- function() {
  models <- list(
    lm(hp ~ wt, data = mtcars),
    lm(hp ~ wt + qsec, data = mtcars),
    lm(hp ~ wt + qsec + am, data = mtcars)
  )
  coefs <- c(wt = "Weight (1000 lbs)", qsec = "1/4 mile time (s)", am = "Manual")

  header <- paste0(padl(""), "&", paste(sprintf("\\multicolumn{1}{c}{(%d)}", seq_along(models)),
                                          collapse = "&"), "\\\\")

  body <- character(0)
  for (v in names(coefs)) {
    est_cells <- character(0)
    se_cells  <- character(0)
    for (m in models) {
      tm <- broom::tidy(m)
      row <- tm[tm$term == v, ]
      if (nrow(row) == 0) {
        est_cells <- c(est_cells, pad(""))
        se_cells  <- c(se_cells, pad(""))
      } else {
        est_cells <- c(est_cells, pad(paste0(sprintf("%.3f", row$estimate), stars(row$p.value))))
        se_cells  <- c(se_cells, pad(paste0("(", sprintf("%.3f", row$std.error), ")")))
      }
    }
    body <- c(body,
      paste0(padl(coefs[[v]]), "&", paste(est_cells, collapse = "&"), "\\\\"),
      paste0(padl(""), "&", paste(se_cells, collapse = "&"), "\\\\"))
  }

  glances <- lapply(models, broom::glance)
  r2_cells <- vapply(glances, function(g) pad(sprintf("%.3f", g$r.squared)), character(1))
  n_cells  <- vapply(models, function(m) pad(sprintf("%.0f", nobs(m))), character(1))
  stats <- c(
    paste0(padl("R-squared"), "&", paste(r2_cells, collapse = "&"), "\\\\"),
    paste0(padl("Observations"), "&", paste(n_cells, collapse = "&"), "\\\\")
  )

  tex <- wrap_house_table(length(models), header, body, stats)
  write_table(tex, "regression")
}

# ==============================================================================
# balance — two-group comparison: mean of each variable by group, the difference,
# and its significance. Analogue of tab_balance (there: by foreign; here: by am,
# relabeled Automatic/Manual — see README.md).
# ==============================================================================
tab_balance <- function() {
  vars <- c(mpg = "Mileage (mpg)", hp = "Horsepower", wt = "Weight (1000 lbs)")
  header <- paste0(padl(""), "&", pad("Automatic"), "&", pad("Manual"), "&",
                     pad("Diff.", 16), "&", pad("t"), "\\\\")

  rows <- vapply(names(vars), function(v) {
    x0 <- mtcars[[v]][mtcars$am == 0]
    x1 <- mtcars[[v]][mtcars$am == 1]
    tt <- t.test(x0, x1)
    diff_cell <- paste0(sprintf("%.1f", mean(x0) - mean(x1)), stars(tt$p.value))
    paste0(
      padl(vars[[v]]), "&", pad(sprintf("%.1f", mean(x0))), "&",
      pad(sprintf("%.1f", mean(x1))), "&", pad(diff_cell, 16), "&",
      pad(sprintf("(%.2f)", unname(tt$statistic))), "\\\\"
    )
  }, character(1))

  tex <- wrap_house_table(4, header, rows)
  write_table(tex, "balance")
}

# --- main — build every table. Comment out a line to skip that table. -----------
main <- function() {
  init()
  tab_summary()
  tab_correlation()
  tab_regression()
  tab_balance()
  cat(">> tables.R complete\n")
}

main()
