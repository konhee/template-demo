#!/usr/bin/env Rscript
# analysis.R — SKELETON for an R pipeline script. Copy this to start.
#
# PERMANENT REFERENCE. Not on the Make graph. The canonical shape an R
# build/analysis script follows: a header naming inputs/outputs, root-anchored path
# constants, a `main()` doing the work, and a run-guard at the bottom. It runs as-is
# (writes one tiny CSV under this folder's output/, no data/ needed) so you can run
# it once to see the pattern, then swap in your real read/transform/write.
#
# R is BEST-EFFORT in this template: unlike Python (environment.yml) and Stata
# (code/lib/stata/dependencies.do), no R dependency manifest ships — a project that
# leans on R should add its own (e.g. renv). This skeleton uses base R only.
#
# The conventions this demonstrates (keep them when you copy):
#   - PROJ_ROOT found from this script's own path, so paths work from any cwd.
#   - All I/O paths as constants up top, anchored at PROJ_ROOT — never relative to
#     the cwd, never hardcoded absolute.
#   - main() reads only from data/raw or data/derived, writes only to its own output.
#   - dir.create(recursive = TRUE) before writing; print what was written.
#
# Output: code/reference/skeletons/output/skeleton_r.csv
#
# Usage:
#     Rscript code/reference/skeletons/analysis.R

# --- locate the repo root, so paths work regardless of the working directory ----
# Rscript exposes its own path via the --file= argument; parse it, then climb. This
# file sits THREE levels below the root (code/reference/skeletons/); a real script in
# code/build/ or code/analysis/ is TWO levels below — match the climb to where you copy it.
this_file <- sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))
proj_root <- normalizePath(file.path(dirname(this_file), "..", "..", ".."))
out_dir   <- file.path(proj_root, "code", "reference", "skeletons", "output")
out_file  <- file.path(out_dir, "skeleton_r.csv")
# A real script would also anchor its inputs here, pointing at the producer
# namespace it reads, e.g.:
#   derived_dir <- file.path(proj_root, "data", "derived", "build")

# --- build_demo_frame — stand in for the real read + transform step -------------
# (one helper per logical step; a real script would read with read.csv(file.path(
# derived_dir, "...")) and transform).
build_demo_frame <- function() {
  data.frame(x = 1:3, x_squared = (1:3)^2)
}

# --- main — read -> transform -> write ------------------------------------------
main <- function() {
  df <- build_demo_frame()

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(df, out_file, row.names = FALSE)

  cat(sprintf(">> wrote %s: %d rows\n",
              sub(paste0(proj_root, .Platform$file.sep), "", out_file, fixed = TRUE),
              nrow(df)))
}

main()
