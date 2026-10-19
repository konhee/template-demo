# code/model/

The **quantitative-model stage**: solve a structural/quantitative model and produce
paper-facing figures and tables. This is where a calibrated or estimated model lives —
the counterpart to `analysis/`'s reduced-form estimation.

**Off the default build graph**, like `fetch/`. Solving is slow and often GUI-interactive
(MATLAB/Julia), so it is not included in the normal build: run it deliberately with
`make model`. `make all` assumes the tracked `output/` the model stage produces already
exists; `make full` runs it inline as part of a from-scratch rebuild (`data → analysis →
model → docs`). A project with no quantitative model simply leaves this folder empty (the
stage is a no-op).

## The model stage is multi-language and sequential

Later steps often depend on earlier ones' output (e.g. a solver followed by diagnostics,
a counterfactual, or a plot) — order matters, so number them. In the demo, one step
**solves** (MATLAB/Julia) and the next **plots** it (Stata/Python) — *"MATLAB/Julia
exports data, Stata/Python plots."* `make model` dispatches every language (`.m`/`.jl`/
`.do`/`.py`/`.R`), so every step lives here together, run in one command.

Scripts run in sorted-filename order, so number them: the solver runs before its
diagnostic.

```
code/model/
├── step01_solve.m               solve the model, write data/derived/model/*.csv
└── step02_plot_transition.do    read that, write output/figures/…  (a model diagnostic)
```

Note the `step01_` / `step02_` prefix rather than a bare `01_`: MATLAB cannot execute an
m-file whose name starts with a digit (it reads the leading digits as a number), so a
letter-led, zero-padded prefix is used uniformly across the stage. See the naming
conventions in `../README.md`.

## Downstream model code stays here

Any code that consumes model output — a diagnostic comparing the solved model against
the data, a counterfactual, a comparison table — belongs to this stage, right beside the
solver, as a later-numbered step. Keeping it here means there is **no `analysis → model →
analysis` back-edge**: nothing in `analysis/` reads model output in the common case, and
`make full` stays a single linear pass. (Nothing *forbids* `analysis/` from reading
`data/derived/model/` — a combined structural + reduced-form table is fine — it just
isn't the default home for such code.)

## Inputs and outputs

- **Reads** — the model's own primitives (a self-contained calibration needs no `data/`
  input), and, when a model is calibrated to estimated moments, `data/derived/analysis/`.
  That `analysis → model` coupling is handled by the on-disk `data/derived/` namespaces
  plus a deliberate re-run, not by Make (model is off-graph).
- **Writes** — solution data to its own producer namespace `data/derived/model/`
  (gitignored, regenerates), and curated figures/tables to the top-level `output/`
  (tracked, so a fresh clone compiles the documents without a MATLAB install).
