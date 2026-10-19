# Makefile — orchestrates the whole project.
#
#   Pipeline:  code/fetch → data/raw → code/build → data/derived/build
#                          → code/analysis → output → writing/{paper,slides,notes}
#   Off the default graph:  code/fetch (network) and code/model (slow solve).
#
# Common targets:
#   make            → same as `make all`
#   make fetch      → pull raw data (network; run deliberately, off the default graph)
#   make data       → clean raw data into data/derived/build  (code/build)
#   make analysis   → produce figures/tables into output/      (code/analysis)
#   make model      → solve the quantitative model (slow; run deliberately, off the graph)
#   make paper      → compile writing/paper
#   make slides     → compile writing/slides
#   make notes      → compile writing/notes
#   make docs       → compile all documents
#   make all        → data → analysis → docs   (does NOT fetch or solve the model)
#   make full       → data → analysis → model → docs   (from-scratch rebuild incl. solve)
#   make clean      → remove data/derived, output artifacts, and LaTeX aux files
#   make distclean  → clean + remove fetched raw data
#
# Machine-specific tool paths (Stata binary, etc.) live in config.mk.

include config.mk

# --- run helpers ---------------------------------------------------------------
# A .do file run in batch mode; abstracts the per-OS invocation from config.mk.
#
# Stata batch mode ALWAYS writes <doname>.log into the current directory and has
# no flag to suppress it. Left alone, every run litters the repo root. So we cd
# into $(STAMP)/logs first and pass an ABSOLUTE path to the .do -- the log lands
# there instead of the root. This is safe because setup.do climbs from cwd to the
# repo root (via its sentinels), so every relative path inside the .do still
# resolves. Logs stay in the (gitignored) .make/ tree next to the stage stamps;
# a failed run leaves its log there for a post-mortem. mkdir -p inside the subshell
# (idempotent) so logs/ always exists even if .make/ has stamps but no logs/ yet --
# the order-only $(STAMP) prereq only fires when .make/ itself is missing.
#
# Stata batch mode exits 0 to the shell REGARDLESS of whether the .do file errored
# -- an uncaught error just gets logged (e.g. `r(199);`) with no signal to make, so
# a failing script would otherwise be silently skipped and the stage stamp touched
# as if everything succeeded. We can't trust the exit code, so we inspect the log
# Stata just wrote instead: a successful run's log always ends with the literal
# line `end of do-file`; an uncaught error appends one more line after that (the
# error code). We check the LAST line specifically, not `grep -q 'r('` anywhere in
# the log -- a .do file that wraps a risky command in `capture` and recovers on
# purpose still legitimately ends with `end of do-file`, and that must NOT be
# flagged as a failure.
define run_stata
	( mkdir -p $(STAMP)/logs && cd $(STAMP)/logs && $(STATA) $(STATA_BATCH) $(CURDIR)/$(1) ; \
	  logf=$(basename $(notdir $(1))).log ; \
	  if [ "$$(tail -n 1 "$$logf" 2>/dev/null)" != "end of do-file" ]; then \
	    echo "run_stata: $(1) FAILED -- see $(STAMP)/logs/$$logf" >&2 ; \
	    exit 1 ; \
	  fi )
endef

# A MATLAB .m file run headless. `matlab -batch "<code>"` (R2019a+) runs the code,
# suppresses the splash/desktop, and — crucially — exits non-zero if it errors, so
# make halts on a failed solve. -batch takes a STATEMENT, not a path, so we pass
# run('<abs>.m') to execute the script file directly (works whether the .m is a
# script or a function, no cd/path juggling). Like run_stata this is quiet: stdout
# +stderr are redirected to a log under $(STAMP)/logs/ for a post-mortem (a bare
# pipe to `tee` would mask MATLAB's exit status and break halt-on-error). Repo-root
# climbing inside the .m still resolves because run() takes an absolute path. NOTE:
# assumes `matlab -batch` (verify on a machine with MATLAB); older releases used
# `-r ... quit` with no non-zero exit, which this deliberately does not use.
define run_matlab
	( mkdir -p $(STAMP)/logs && $(MATLAB) $(MATLAB_BATCH) "run('$(CURDIR)/$(1)')" > $(STAMP)/logs/$(notdir $(1)).log 2>&1 )
endef

# Sentinel dir: Stata/Python scripts don't declare their outputs, so we touch a
# stamp file after a stage succeeds and depend on stamps to sequence stages.
STAMP := .make

$(STAMP):
	@mkdir -p $(STAMP)/logs

# --- scripts -------------------------------------------------------------------
# Collected RECURSIVELY (find, not $(wildcard)) so a stage may subfolder its scripts
# once it outgrows a flat layout without silently dropping the nested ones. `sort`
# gives a deterministic run order, so numeric prefixes (01_solve.m, 02_fit.do) run
# in sequence. The extension set matches run_script's dispatch (.do/.py/.R/.m/.jl);
# find is fine here because the pipeline runs on Linux/macOS (Windows use is
# LaTeX-only). 2>/dev/null so a not-yet-created stage dir (e.g. code/model) is a
# silent no-op, matching the empty-stage graceful-skip contract.
find_src = $(shell find $(1) \( -name '*.do' -o -name '*.py' -o -name '*.R' -o -name '*.m' -o -name '*.jl' \) 2>/dev/null | sort)
FETCH_SRC    := $(call find_src,code/fetch)
BUILD_SRC    := $(call find_src,code/build)
ANALYSIS_SRC := $(call find_src,code/analysis)
MODEL_SRC    := $(call find_src,code/model)

# ==============================================================================
# Pipeline
# ==============================================================================

# `docs` compiles the TRACKED output/ artifacts and does NOT depend on analysis
# (see the documents section for why). So `all` sequences the two stages itself,
# via recursive sub-makes: this guarantees analysis finishes before docs starts
# EVEN under parallel make (-j), which an ordinary `all: analysis docs` prereq
# list would let race. Each sub-make may still parallelize within its own stage.
.PHONY: all
all:
	$(MAKE) analysis
	$(MAKE) docs

# `full` is the from-scratch reproducibility rebuild: it additionally solves the
# model, which `all` deliberately skips (model is off the default graph, like fetch).
# A single linear pass suffices — fit-diagnostics live in code/model/ (numbered AFTER
# the solver), so the solve and any "model vs. data" comparison both complete within
# `make model`; there is no model→analysis back-edge that would need a second analysis
# pass. Recursive sub-makes enforce order even under -j.
.PHONY: full
full:
	$(MAKE) data
	$(MAKE) analysis
	$(MAKE) model
	$(MAKE) docs

# --- fetch: pull raw data (network). Deliberately OFF the default graph. -------
.PHONY: fetch
fetch: | $(STAMP)
	@echo ">> fetch: pulling raw data into data/raw/"
	@$(foreach f,$(FETCH_SRC),$(call run_script,$(f)) &&) true
	@touch $(STAMP)/fetch

# --- data: raw → derived/build -------------------------------------------------
.PHONY: data
data: $(STAMP)/build
$(STAMP)/build: $(BUILD_SRC) | $(STAMP)
	@echo ">> build: data/raw → data/derived/build"
	@$(foreach f,$(BUILD_SRC),$(call run_script,$(f)) &&) true
	@touch $@

# --- analysis: derived → output ------------------------------------------------
.PHONY: analysis
analysis: $(STAMP)/analysis
$(STAMP)/analysis: $(ANALYSIS_SRC) $(STAMP)/build | $(STAMP)
	@echo ">> analysis: data/derived → output/"
	@$(foreach f,$(ANALYSIS_SRC),$(call run_script,$(f)) &&) true
	@touch $@

# --- model: solve the quantitative model. Deliberately OFF the default graph. --
# Slow and often run interactively (MATLAB GUI) during development, so like fetch it
# is never pulled in by `all`; `all` assumes its output already exists on disk under
# data/derived/model/. No data prerequisite: a pure-simulation model runs frictionlessly
# on a bare clone; a data-calibrated model reads reduced-form moments from
# data/derived/analysis/ that you produced with `make analysis` first (sequenced by hand,
# since model is off-graph — or in one shot via `make full`).
.PHONY: model
model: | $(STAMP)
	@echo ">> model: solving into data/derived/model/ and output/"
	@$(foreach f,$(MODEL_SRC),$(call run_script,$(f)) &&) true
	@touch $(STAMP)/model

# Dispatch a script by extension: .do -> Stata (batch, logged), .m -> MATLAB (headless,
# logged), .R -> Rscript, .jl -> Julia, .py -> Python. An UNKNOWN extension is a hard
# error rather than a silent fall-through to Python (which would mis-run a stray .sh/etc.).
define run_script
	$(if $(filter %.do,$(1)),$(call run_stata,$(1)),\
	$(if $(filter %.m,$(1)),$(call run_matlab,$(1)),\
	$(if $(filter %.R,$(1)),$(RSCRIPT) $(1),\
	$(if $(filter %.jl,$(1)),$(JULIA) $(1),\
	$(if $(filter %.py,$(1)),$(PYTHON) $(1),\
	$(error run_script: unknown extension for '$(1)' — teach run_script to dispatch it))))))
endef

# ==============================================================================
# Documents  (latexmk runs lualatex + bibtex the right number of times)
# ==============================================================================

# Each document target compiles EVERY *.tex in its directory (via wildcard).
# latexmk skips true subfiles automatically (a \documentclass[..]{subfiles} file
# builds fine on its own), so globbing is safe here.
PAPER_SRC  := $(wildcard writing/paper/*.tex)
SLIDES_SRC := $(wildcard writing/slides/*.tex)
NOTES_SRC  := $(wildcard writing/notes/*.tex)

.PHONY: docs paper slides notes
# notes are intentionally excluded from `docs` (compile manually: make notes,
# or run latexmk in writing/notes directly)
docs: paper slides

# Documents compile the TRACKED artifacts in output/ (figures via \includegraphics,
# tables via \input) and deliberately DO NOT depend on the analysis stage. This is
# the template's contract: output/ and the compiled PDFs are committed, so a fresh
# clone -- which has no data/ and no .make/ stamps (both gitignored) -- can build
# every document with no data, no fetch, and no analysis run. Chaining docs to the
# analysis stamp would drag a clone all the way back to `make fetch` and fail for
# lack of raw data.
#
# TRADEOFF (by design, do not "fix"): on a machine that HAS data, editing an
# analysis script and running `make docs` will NOT refresh the figures/tables --
# run `make analysis` (or `make all`) first. Freshness requires the pipeline to
# run, which requires data a clone does not have; the two goals are irreconcilable
# and we choose "a clone always compiles." Contract: `make docs` = compile tracked
# outputs; `make analysis` = refresh output/; `make all` = both, correctly ordered.
paper:
	@echo ">> compiling writing/paper (all *.tex)"
	@for f in $(notdir $(PAPER_SRC)); do \
		echo "   -> $$f"; \
		( cd writing/paper && $(LATEXMK) $(LATEXMK_FLAGS) $$f ) || exit $$?; \
	done

slides:
	@echo ">> compiling writing/slides (all *.tex)"
	@for f in $(notdir $(SLIDES_SRC)); do \
		echo "   -> $$f"; \
		( cd writing/slides && $(LATEXMK) $(LATEXMK_FLAGS) $$f ) || exit $$?; \
	done

notes:
	@echo ">> compiling writing/notes (all *.tex)"
	@for f in $(notdir $(NOTES_SRC)); do \
		echo "   -> $$f"; \
		( cd writing/notes && $(LATEXMK) $(LATEXMK_FLAGS) $$f ) || exit $$?; \
	done

# ==============================================================================
# Cleaning
# ==============================================================================

.PHONY: clean distclean clean-tex clean-fontcache
clean: clean-tex
	@echo ">> removing data/derived, output artifacts, and build stamps"
	rm -rf data/derived/* output/figures/* output/tables/*
	rm -rf $(STAMP)
	@touch output/figures/.gitkeep output/tables/.gitkeep

# latexmk -C removes ALL generated files including the PDF; -c keeps the PDF.
clean-tex:
	@echo ">> removing LaTeX aux files"
	-cd writing/paper  && $(LATEXMK) -c
	-cd writing/slides && $(LATEXMK) -c
	-cd writing/notes  && $(LATEXMK) -c

# Flush luaotfload's font cache. Preambles use an ABSOLUTE Path= (see any supp/
# preamble), which makes the cache collision-proof, so this should essentially
# never be needed now. Kept as an explicit ESCAPE HATCH for a genuinely corrupt
# cache or a legacy poisoned entry from an old relative-path build (symptom:
# "cannot find file ''" at PDF shipout -- doc renders fully, then dies at the end).
# NOT wired into distclean on purpose: the cache is shared, user-global state in
# ~/.texlive.../luatex-cache/, outside this repo, and erasing it slows the next
# compile of EVERY project on the machine. Run it deliberately when you mean to.
clean-fontcache:
	@echo ">> erasing luaotfload font cache (escape hatch; not part of clean/distclean)"
	-luaotfload-tool --cache=erase

distclean: clean
	@echo ">> removing fetched raw data"
	rm -rf data/raw/*
