%! analysis.m -- SKELETON for a MATLAB model/analysis script. Copy this to start.
%
% PERMANENT REFERENCE, not on the Make graph. The shape a model-stage .m follows:
% locate the repo root, do the work in one main function, export results as data for
% a downstream .do/.py to plot. Runs as-is (writes one tiny CSV under this folder's
% output/, no data/ needed) -- run it once to see the pattern, then swap in your model.
%
% Why export data instead of plotting here: the house division of labour is "MATLAB
% (or Julia) solves and exports; Stata/Python plots." So a real model step writes its
% solution to data/derived/model/ and a sibling .do/.py in code/model/ draws the
% figure. See the worked demo in code/model/ (step01_solve.m + step02_plot_transition.do).
%
% ASCII ONLY: MATLAB's parser rejects non-ASCII bytes in source (a stray "smart quote"
% or en-dash aborts with "Invalid text character"). Keep comments plain ASCII.
%
% Run it (off the Makefile -- from anywhere in the repo):
%     matlab -batch "run('code/reference/skeletons/analysis.m')"

% --- locate the repo root, so paths work regardless of MATLAB's cwd -------------
% -batch runs this via run('<abs path>'), so mfilename('fullpath') is absolute.
% This file sits THREE levels below the root (code/reference/skeletons/); a real
% model script in code/model/ is ONE level below, so it climbs one fewer fileparts --
% match the climb to wherever you copy this.
thisFile  = mfilename('fullpath');                 % .../skeletons/analysis  (no ext)
projRoot  = fileparts(fileparts(fileparts(fileparts(thisFile))));  % repo root
outDir    = fullfile(projRoot, 'code', 'reference', 'skeletons', 'output');
outFile   = fullfile(outDir, 'skeleton_m.csv');
% A real model script writes to its own producer namespace instead, e.g.:
%   outDir = fullfile(projRoot, 'data', 'derived', 'model');
if ~exist(outDir, 'dir'); mkdir(outDir); end

% --- do the work, then export ---------------------------------------------------
% main() is a function so locals don't leak into the base workspace; call it at the
% end (a script file may define functions after the top-level code, R2016b+).
main(outDir, outFile, projRoot);

function main(outDir, outFile, projRoot)
    % Stand in for the real solve + transform. A real script would solve the model
    % here and assemble a results table.
    tbl = buildDemoTable();

    if ~exist(outDir, 'dir'); mkdir(outDir); end
    writetable(tbl, outFile);

    fprintf('>> wrote %s: %d rows\n', ...
            strrep(outFile, [projRoot filesep], ''), height(tbl));
end

function tbl = buildDemoTable()
    % One helper per logical step; here a trivial x, x^2 frame.
    x = (1:3)';
    tbl = table(x, x.^2, 'VariableNames', {'x', 'x_squared'});
end
