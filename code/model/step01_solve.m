%! step01_solve.m -- SOLVE step of the model stage (worked MATLAB demo).
%
% The `model` stage, step 1: solve a small quantitative model and EXPORT its
% solution as data for a downstream diagnostic to plot. This demo is a textbook
% Solow growth model -- self-contained (no data/ input, a pure simulation), so it
% runs on a bare clone and illustrates the pattern without project specifics:
%   solve in MATLAB  ->  write a CSV to data/derived/model/  ->  a .do/.py plots it.
% That division of labour ("MATLAB exports data, Stata/Python plots") is why the
% plotter (step02_plot_transition.do) lives HERE in code/model/ beside the solver, not
% in code/analysis/: a model's own fit/diagnostic output belongs to the model stage.
%
% Prefixed step01_ because the model stage is sequential: the solver must run before
% the plotter (the Makefile's sorted `find` guarantees step01_ before step02_). The
% "step" is a letter, not a bare digit, because MATLAB cannot execute an m-file whose
% name starts with a digit -- it reads the leading digits as a number.
%
% Output: data/derived/model/solow_transition.csv
%   t   k   y   c        (period; capital, output, consumption per effective worker)
%
% Run it (off the default graph -- solving is slow / often interactive):
%     make model
% or directly:
%     matlab -batch "run('code/model/step01_solve.m')"

% --- locate the repo root, so paths work regardless of MATLAB's cwd -------------
% -batch runs this via run('<abs path>'), so mfilename('fullpath') is absolute.
% This file is code/model/step01_solve.m, so the root is two folders up from its dir.
thisFile = mfilename('fullpath');            % .../code/model/step01_solve  (no extension)
modelDir = fileparts(thisFile);              % .../code/model
projRoot = fileparts(fileparts(modelDir));   % repo root
derivedDir = fullfile(projRoot, 'data', 'derived', 'model');   % this stage's namespace
if ~exist(derivedDir, 'dir'); mkdir(derivedDir); end

% --- model primitives (annual calibration) --------------------------------------
alpha = 0.33;    % capital share
delta = 0.06;    % depreciation
s     = 0.22;    % saving rate
n     = 0.01;    % population growth
g     = 0.02;    % technology growth
T     = 100;     % periods to simulate

% Steady state (per effective worker): s k^alpha = (n+g+delta) k
kStar = (s / (n + g + delta))^(1 / (1 - alpha));

% --- solve the transition from a low initial capital stock ----------------------
k = zeros(T, 1);
k(1) = 0.10 * kStar;                          % start well below steady state
for t = 1:(T - 1)
    y_t    = k(t)^alpha;                      % output per effective worker
    inv_t  = s * y_t;                         % saving = investment
    k(t+1) = (inv_t + (1 - delta) * k(t)) / ((1 + n) * (1 + g));
end

y = k .^ alpha;         % output per effective worker
c = (1 - s) .* y;       % consumption per effective worker
t = (0:(T - 1))';       % period index, 0-based

% --- export the solution as tidy data (the diagnostic reads this) ---------------
outFile = fullfile(derivedDir, 'solow_transition.csv');
writetable(table(t, k, y, c), outFile);

fprintf('>> wrote %s: %d periods, k_star = %.3f\n', ...
        strrep(outFile, [projRoot filesep], ''), T, kStar);
