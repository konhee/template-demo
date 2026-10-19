# code/lib/matlab — shared MATLAB helpers

## Files

- **`mtcars.m`** — the classic `mtcars` dataset as a literal MATLAB `table` (one row per
  car), since MATLAB has no built-in equivalent. Same source and values as
  `../py/mtcars.py`. Used by `../../reference/matlab/figures.m` and `tables.m`.

## How a script pulls this in

MATLAB has no ado-path equivalent — Stata's `setup.do` puts `code/lib/stata/` on the ado
path so vendored files are found by name; MATLAB scripts instead `addpath` this folder
and call the function directly, after computing `projRoot` the same way
`code/reference/skeletons/analysis.m` does:

```matlab
thisFile = mfilename('fullpath');
projRoot = fileparts(fileparts(fileparts(fileparts(thisFile))));  % match the climb to wherever you copy this
addpath(fullfile(projRoot, 'code', 'lib', 'matlab'));
df = mtcars();
```

Works in MATLAB or Octave.
