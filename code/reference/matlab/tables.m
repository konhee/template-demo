%! tables.m -- samples of the house table style, in MATLAB.
%
% PERMANENT REFERENCE. Not on the Make graph, not part of the project's analysis.
% The MATLAB companion to ../stata/tables.do and ../r/tables.R: builds one table
% of each kind, from code/lib/matlab/mtcars.m (no data/ dependency, no network --
% see README.md for the exact variable substitutions used throughout, mirroring
% figures.m), and writes each as a .tex fragment into this folder's tracked
% output/tables/ -- structurally parallel to the Stata esttab fragments (same
% \doublerule / \midrule shape, same \sym{} significance stars), so this file
% doubles as the copy-paste reference for the house table look in MATLAB. A
% deliberate, explicit exception to code/model/README.md's stated "MATLAB
% solves and exports; Stata/Python plots" division of labour -- see README.md.
%
% This is the table companion to figures.m in this folder.
%
% Needs Statistics and Machine Learning Toolbox (fitlm, for tabRegression only).
%
% Table menu (function per table; comment out a line in main() to skip one):
%   summary      descriptive stats: mean / sd / min / max / N
%   correlation  pairwise correlation matrix
%   regression   nested OLS specs with stars, SEs, r2/N (fitlm)
%   balance      two-group means, difference, significance (two-sample t-test)
%
% Run it (off the Makefile -- invoke by hand, from anywhere in the repo):
%     matlab -batch "run('code/reference/matlab/tables.m')"

% --- locate the repo root, so paths work regardless of MATLAB's cwd -------------
thisFile = mfilename('fullpath');
projRoot = fileparts(fileparts(fileparts(fileparts(thisFile))));
tabDir = fullfile(projRoot, 'code', 'reference', 'matlab', 'output', 'tables');

addpath(fullfile(projRoot, 'code', 'lib', 'matlab'));

% --- init -- create the output dir (this file's own tracked output/tables/). ----
% ==================================================================================
if ~exist(tabDir, 'dir'); mkdir(tabDir); end

% --- main -- build every table. Comment out a line to skip that table. ----------
tabSummary(tabDir);
tabCorrelation(tabDir);
tabRegression(tabDir);
tabBalance(tabDir);
fprintf('>> tables.m complete\n');

% --- stars -- the house significance convention: * 0.10 ** 0.05 *** 0.01,
% wrapped in \sym{} to match the esttab-produced fragments in ../stata/output/tables/.
% ==================================================================================
function s = stars(p)
    if p < 0.01
        s = '\sym{***}';
    elseif p < 0.05
        s = '\sym{**}';
    elseif p < 0.10
        s = '\sym{*}';
    else
        s = '';
    end
end

% --- pad/padl -- right/left-justify a string to a fixed width (cosmetic only: a
% tabular's columns align regardless of padding, but this keeps the raw .tex
% fragment readable, matching the fixed-width look of the esttab output it mirrors).
% ==================================================================================
function s = pad(x, width)
    if nargin < 2; width = 9; end
    s = sprintf(['%' num2str(width) 's'], x);
end

function s = padl(x, width)
    if nargin < 2; width = 16; end
    s = sprintf(['%-' num2str(width) 's'], x);
end

% --- wrapHouseTable -- assemble a full tabular from a header row, body rows, and
% optional stats rows, using the SAME shape every ../stata/tables.do fragment
% shares: \doublerule at the top, \midrule under the header, \midrule before any
% stats block, \midrule to close. See README.md for why all four Stata table
% types reduce to this one shape.
% ==================================================================================
function tex = wrapHouseTable(ncol, header, body, stats)
    lines = [{sprintf('\\begin{tabular}{l*{%d}{c}}', ncol), '\doublerule', header, '\midrule'}, body];
    if nargin >= 4 && ~isempty(stats)
        lines = [lines, {'\midrule'}, stats];
    end
    lines = [lines, {'\midrule', '\end{tabular}'}];
    tex = strjoin(lines, '\n');
end

function writeTable(tex, name, tabDir)
    outFile = fullfile(tabDir, [name '.tex']);
    fid = fopen(outFile, 'w');
    fprintf(fid, '%s\n', tex);
    fclose(fid);
    fprintf('>> wrote %s\n', outFile);
end

% ==================================================================================
% summary -- descriptive statistics: mean / sd / min / max / N, one row per var.
% Analogue of tab_summary in ../stata/tables.do (there: price/mpg/weight/length;
% here: mpg/hp/wt/qsec, see README.md for the mtcars substitution).
% ==================================================================================
function tabSummary(tabDir)
    df = mtcars();
    vars = {'mpg', 'hp', 'wt', 'qsec'};
    labels = {'Mileage (mpg)', 'Horsepower', 'Weight (1000 lbs)', '1/4 mile time (s)'};

    rows = cell(1, numel(vars));
    for k = 1:numel(vars)
        x = df.(vars{k});
        rows{k} = [padl(labels{k}) '&' pad(sprintf('%.2f', mean(x))) '&' ...
            pad(sprintf('%.2f', std(x))) '&' pad(sprintf('%.0f', min(x))) '&' ...
            pad(sprintf('%.0f', max(x))) '&' pad(sprintf('%d', numel(x))) '\\'];
    end

    header = [padl('') '&' pad('Mean') '&' pad('SD') '&' pad('Min') '&' pad('Max') '&' pad('N') '\\'];
    tex = wrapHouseTable(5, header, rows);
    writeTable(tex, 'summary', tabDir);
end

% ==================================================================================
% correlation -- pairwise Pearson correlation matrix (lower triangle). Analogue
% of tab_correlation: not/nostar (no stars, no t-stats), lower-triangle only.
% ==================================================================================
function tabCorrelation(tabDir)
    df = mtcars();
    vars = {'mpg', 'hp', 'wt', 'qsec'};
    labels = {'Mileage', 'Horsepower', 'Weight', '1/4 mile'};
    m = corr(df{:, vars});

    header = ['&' strjoin(labels, ' & ') ' \\'];
    rows = cell(1, numel(vars));
    for i = 1:numel(vars)
        cells = cell(1, numel(vars));
        for j = 1:numel(vars)
            if j <= i
                cells{j} = pad(sprintf('%.3f', m(i, j)));
            else
                cells{j} = '';
            end
        end
        rows{i} = [padl(labels{i}) '&' strjoin(cells, '&') '\\'];
    end

    tex = wrapHouseTable(numel(vars), header, rows);
    writeTable(tex, 'correlation', tabDir);
end

% ==================================================================================
% regression -- the workhorse econ table: nested OLS specs side by side, stars,
% SEs below in parentheses, r2/N at the foot. Analogue of tab_regression (there:
% price on weight/mpg/foreign; here: hp on wt/qsec/am -- horsepower as the
% continuous outcome, see README.md).
% ==================================================================================
function tabRegression(tabDir)
    df = mtcars();
    specs = {'hp ~ wt', 'hp ~ wt + qsec', 'hp ~ wt + qsec + am'};
    models = cellfun(@(s) fitlm(df, s), specs, 'UniformOutput', false);
    coefVars = {'wt', 'qsec', 'am'};
    coefLabels = {'Weight (1000 lbs)', '1/4 mile time (s)', 'Manual'};

    headerCells = cell(1, numel(models));
    for k = 1:numel(models)
        headerCells{k} = pad(sprintf('\\multicolumn{1}{c}{(%d)}', k));
    end
    header = [padl('') '&' strjoin(headerCells, '&') '\\'];

    body = {};
    for k = 1:numel(coefVars)
        v = coefVars{k};
        estCells = cell(1, numel(models));
        seCells = cell(1, numel(models));
        for j = 1:numel(models)
            coefTable = models{j}.Coefficients;
            if any(strcmp(coefTable.Row, v))
                est = coefTable.Estimate(v);
                se = coefTable.SE(v);
                p = coefTable.pValue(v);
                estCells{j} = pad(sprintf('%.3f%s', est, stars(p)));
                seCells{j} = pad(sprintf('(%.3f)', se));
            else
                estCells{j} = pad('');
                seCells{j} = pad('');
            end
        end
        body{end+1} = [padl(coefLabels{k}) '&' strjoin(estCells, '&') '\\']; %#ok<AGROW>
        body{end+1} = [padl('') '&' strjoin(seCells, '&') '\\']; %#ok<AGROW>
    end

    r2Cells = cellfun(@(m) pad(sprintf('%.3f', m.Rsquared.Ordinary)), models, 'UniformOutput', false);
    nCells = cellfun(@(m) pad(sprintf('%d', m.NumObservations)), models, 'UniformOutput', false);
    stats = {
        [padl('R-squared') '&' strjoin(r2Cells, '&') '\\'], ...
        [padl('Observations') '&' strjoin(nCells, '&') '\\']
    };

    tex = wrapHouseTable(numel(models), header, body, stats);
    writeTable(tex, 'regression', tabDir);
end

% ==================================================================================
% balance -- two-group comparison: mean of each variable by group, the
% difference, and its significance. Analogue of tab_balance (there: by foreign;
% here: by am, relabeled Automatic/Manual -- see README.md).
% ==================================================================================
function tabBalance(tabDir)
    df = mtcars();
    vars = {'mpg', 'hp', 'wt'};
    labels = {'Mileage (mpg)', 'Horsepower', 'Weight (1000 lbs)'};
    header = [padl('') '&' pad('Automatic') '&' pad('Manual') '&' pad('Diff.', 16) '&' pad('t') '\\'];

    rows = cell(1, numel(vars));
    for k = 1:numel(vars)
        x0 = df.(vars{k})(df.am == 0);
        x1 = df.(vars{k})(df.am == 1);
        [~, p, ~, stats] = ttest2(x0, x1, 'Vartype', 'unequal');
        diffCell = sprintf('%.1f%s', mean(x0) - mean(x1), stars(p));
        rows{k} = [padl(labels{k}) '&' pad(sprintf('%.1f', mean(x0))) '&' ...
            pad(sprintf('%.1f', mean(x1))) '&' pad(diffCell, 16) '&' ...
            pad(sprintf('(%.2f)', stats.tstat)) '\\'];
    end

    tex = wrapHouseTable(4, header, rows);
    writeTable(tex, 'balance', tabDir);
end
