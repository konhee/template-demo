# config.mk — shared build configuration (committed).
#
# This file holds sensible DEFAULTS shared by everyone and is version-controlled.
# Do NOT edit it for machine-specific paths — put those in config.local.mk instead
# (gitignored, per-machine). See config.local.mk.example for the pattern.
#
# The line below pulls in your local overrides FIRST. Because the defaults below
# use `?=` ("set only if not already defined"), anything you set in
# config.local.mk wins automatically — no need to touch this file.
-include config.local.mk

# ---------------------------------------------------------------------------
# Stata
# ---------------------------------------------------------------------------
# Stata is often NOT on PATH and the binary name + batch flag differ by OS:
#   Linux   : stata-mp -b do file.do            (also stata-se / stata)
#   macOS   : /Applications/Stata/StataMP.app/Contents/MacOS/stata-mp -b do file.do
#   Windows : "StataMP-64.exe" /e do file.do    (/e = batch, quit on error)
#
# If Stata is not on PATH, set STATA to its full path in config.local.mk (NOT here).
# STATA_BATCH is the flag(s) that run a .do file in batch mode and exit.

# --- Defaults: Linux / macOS with stata-mp on PATH ---
STATA       ?= stata-mp
STATA_BATCH ?= -b do

# ---------------------------------------------------------------------------
# Python
# ---------------------------------------------------------------------------
PYTHON ?= python

# ---------------------------------------------------------------------------
# R  (optional -- only needed if a pipeline stage has *.R scripts)
# ---------------------------------------------------------------------------
# The Makefile runs `$(RSCRIPT) script.R`. R is best-effort: unlike Python
# (environment.yml) and Stata (code/lib/stata/dependencies.do), the template
# ships no R dependency manifest -- a project that leans on R should add its own.
RSCRIPT ?= Rscript

# ---------------------------------------------------------------------------
# MATLAB  (optional -- only needed if code/model (or another stage) has *.m scripts)
# ---------------------------------------------------------------------------
# The Makefile runs `$(MATLAB) $(MATLAB_BATCH) "run('/abs/path/script.m')"`.
# -batch (R2019a+) runs headless and, unlike the old `-r ... quit`, exits non-zero
# on error so make halts. Set MATLAB to the full binary path in config.local.mk if
# it is not on PATH (e.g. /Applications/MATLAB_R2023b.app/bin/matlab on macOS,
# "C:/Program Files/MATLAB/R2023b/bin/matlab.exe" on Windows). Like R, MATLAB is
# best-effort: the template ships no toolbox manifest -- note required toolboxes in
# your model's README.
MATLAB       ?= matlab
MATLAB_BATCH ?= -batch

# ---------------------------------------------------------------------------
# Julia  (optional -- only needed if a stage has *.jl scripts)
# ---------------------------------------------------------------------------
# The Makefile runs `$(JULIA) script.jl`. Best-effort like R/MATLAB: no shipped
# manifest -- a project leaning on Julia should add its own (e.g. a Project.toml).
JULIA ?= julia

# ---------------------------------------------------------------------------
# LaTeX
# ---------------------------------------------------------------------------
# latexmk drives lualatex + bibtex the correct number of times automatically.
LATEXMK ?= latexmk
LATEXMK_FLAGS ?= -lualatex -interaction=nonstopmode -halt-on-error
