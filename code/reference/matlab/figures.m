%! figures.m -- visual samples of common chart types, in MATLAB.
%
% PERMANENT REFERENCE. Not on the Make graph, not part of the project's analysis.
% The MATLAB companion to ../stata/figures.do and ../r/figures.R: draws the SAME
% menu of chart types under a mono (grayscale) and a color (MATLAB default)
% variant, so a MATLAB-based analysis can match a Stata- or R-based one. A
% deliberate, explicit exception to code/model/README.md's stated "MATLAB
% solves and exports; Stata/Python plots" division of labour -- see README.md
% for why that convention doesn't apply here. Built entirely from
% code/lib/matlab/mtcars.m (a literal copy of R's base mtcars, no data/
% dependency, no network) since MATLAB has no built-in analogue of Stata's
% `sysuse auto`/`uslifeexp` either -- see README.md for the exact variable
% substitutions used throughout (same ones ../r/figures.R uses, since both
% build on the same mtcars values).
%
% Needs: Statistics and Machine Learning Toolbox is NOT required for this file
% (only tables.m's regression needs fitlm). Works in MATLAB or Octave.
%
% Chart menu (function per chart; comment out a line in drawAll() to skip one):
%   scatter      one group, structural marker
%   timeseries   single line, top-left y-label, symmetric x ticks
%   histogram    single distribution
%   eventstudy   coefficients +/- 95% CI around an event, ref period pinned to 0
%   coefplot     coefficients across specs, horizontal, CI whiskers
%   bar          mean per category, single series
%   binscatter   binned means by group (mono distinguishes groups by marker fill)
%   kdensity     overlaid densities by group (mono: solid vs. dashed line)
%   histogramOverlap  translucent histogram fill + density line, overlaid by group
%
% Run it (off the Makefile -- invoke by hand, from anywhere in the repo):
%     matlab -batch "run('code/reference/matlab/figures.m')"
% or, best-effort: octave --eval "run('code/reference/matlab/figures.m')"

% --- locate the repo root, so paths work regardless of MATLAB's cwd -------------
% This file sits THREE levels below the root (code/reference/matlab/), matching
% the skeletons/analysis.m climb.
thisFile = mfilename('fullpath');
projRoot = fileparts(fileparts(fileparts(fileparts(thisFile))));
figDir = fullfile(projRoot, 'code', 'reference', 'matlab', 'output', 'figures');

addpath(fullfile(projRoot, 'code', 'lib', 'matlab'));

mono.suffix = 'mono';
color.suffix = 'color';

% --- init -- create the output dir (this file's own tracked output/figures/,
% colocated with the code that made it, mirroring the Stata/R reference layout).
% ==================================================================================
if ~exist(figDir, 'dir'); mkdir(figDir); end

% --- main -- run the full chart menu per style. -----------------------------------
drawAll(mono, figDir);
fprintf('>> figures.m: mono -> output/figures/*_mono.pdf complete\n');
drawAll(color, figDir);
fprintf('>> figures.m: color -> output/figures/*_color.pdf complete\n');
fprintf('>> figures.m complete\n');

% --- drawAll -- draw every chart under the given style. Comment out a line to
% skip that chart. Called once per style (mono, color).
% ==================================================================================
function drawAll(style, figDir)
    figScatter(style, figDir);
    figTimeseries(style, figDir);
    figHistogram(style, figDir);
    figEventstudy(style, figDir);
    figCoefplot(style, figDir);
    figBar(style, figDir);
    figBinscatter(style, figDir);
    figKdensity(style, figDir);
    figHistogramOverlap(style, figDir);
end

% --- figExport -- write PDF + wide PNG, tagging the filename with the
% mono/color suffix so both variants of a chart sort adjacent.
% ==================================================================================
function figExport(fig, name, style, figDir)
    if ~exist(figDir, 'dir'); mkdir(figDir); end
    stub = fullfile(figDir, [name '_' style.suffix]);
    print(fig, [stub '.pdf'], '-dpdf');
    print(fig, [stub '.png'], '-dpng', '-r200');
    fprintf('>> wrote %s.pdf / .png\n', stub);
end

% ==================================================================================
% scatter (single group). mtcars analogue of sysuse auto's mpg-vs-weight.
% ==================================================================================
function figScatter(style, figDir)
    df = mtcars();
    weightLbs = df.wt * 1000;

    fig = figure('Visible', 'off');
    ax = axes(fig);
    scatter(ax, weightLbs, df.mpg, 60, 'o');
    title(ax, 'Mileage (mpg)');
    xlabel(ax, 'Weight (lbs)');
    figExport(fig, 'scatter', style, figDir);
    close(fig);
end

% ==================================================================================
% time series (single line). No MATLAB built-in analogue of sysuse uslifeexp
% exists, so this uses the same synthetic monotonic-concave curve ../r/figures.R
% uses (rising life expectancy that flattens over the century).
% ==================================================================================
function figTimeseries(style, figDir)
    years = (1900:5:2000)';
    le = 47 + 30 * (1 - exp(-(years - 1900) / 40));

    fig = figure('Visible', 'off');
    ax = axes(fig);
    plot(ax, years, le, 'LineWidth', 2.2);
    title(ax, 'Life expectancy (years)');
    xlabel(ax, 'Year');
    xticks(ax, 1900:20:2000);
    figExport(fig, 'timeseries', style, figDir);
    close(fig);
end

% ==================================================================================
% histogram (single distribution).
% ==================================================================================
function figHistogram(style, figDir)
    df = mtcars();
    edges = (min(df.mpg) - 3):3:(max(df.mpg) + 3);

    fig = figure('Visible', 'off');
    ax = axes(fig);
    histogram(ax, df.mpg, edges, 'Normalization', 'probability');
    ytickformat(ax, 'percentage');
    title(ax, 'Percent');
    xlabel(ax, 'Mileage (mpg)');
    figExport(fig, 'histogram', style, figDir);
    close(fig);
end

% ==================================================================================
% event study. Synthetic coefficients +/- 95% CI around an event at t=0,
% reference period t=-1 pinned to exactly 0 -- same construction as
% ../stata/figures.do and ../r/figures.R.
% ==================================================================================
function figEventstudy(style, figDir)
    t = (-5:5)';
    coef = zeros(size(t));
    coef(t >= 0) = 0.15 * (t(t >= 0) + 1);
    coef(t == -1) = 0;
    se = 0.05 + 0.01 * abs(t);
    se(t == -1) = 0;
    hi = coef + 1.96 * se;
    lo = coef - 1.96 * se;

    fig = figure('Visible', 'off');
    ax = axes(fig);
    hold(ax, 'on');
    fill(ax, [t; flipud(t)], [hi; flipud(lo)], [0.7 0.7 0.7], 'FaceAlpha', 0.5, ...
        'EdgeColor', 'none');
    plot(ax, t, coef, 'LineWidth', 1.8);
    scatter(ax, t, coef, 40);
    yline(ax, 0, 'Color', 'black', 'LineWidth', 0.8);
    xline(ax, 0, 'Color', 'black', 'LineWidth', 0.8);
    hold(ax, 'off');
    xticks(ax, t);
    title(ax, 'Coefficient (95% CI)');
    xlabel(ax, 'Event time');
    figExport(fig, 'eventstudy', style, figDir);
    close(fig);
end

% ==================================================================================
% coefficient plot. Synthetic coefficients across four specifications,
% horizontal, with 95% CI whiskers. Row order top->bottom matches ../r/figures.R's
% rendered layout (Baseline at top, + Cluster at bottom).
% ==================================================================================
function figCoefplot(style, figDir)
    specs = {'Baseline', '+ Controls', '+ FE', '+ Cluster'};
    coefs = [0.35, 0.40, 0.45, 0.50];
    se = repmat(0.06, 1, 4);
    hi = coefs + 1.96 * se;
    lo = coefs - 1.96 * se;

    y = fliplr(1:numel(specs));

    fig = figure('Visible', 'off');
    ax = axes(fig);
    hold(ax, 'on');
    for k = 1:numel(specs)
        plot(ax, [lo(k) hi(k)], [y(k) y(k)], 'Color', [0.3 0.3 0.3], 'LineWidth', 1.4);
    end
    scatter(ax, coefs, y, 60);
    xline(ax, 0, 'Color', 'black', 'LineWidth', 0.8);
    hold(ax, 'off');
    yticks(ax, sort(y));
    yticklabels(ax, fliplr(specs));
    ylim(ax, [0.5 numel(specs) + 0.5]);
    title(ax, 'Specification');
    xlabel(ax, 'Coefficient (95% CI)');
    figExport(fig, 'coefplot', style, figDir);
    close(fig);
end

% ==================================================================================
% bar chart. Mean mpg by cylinder count -- mtcars analogue of mean mpg by rep78.
% ==================================================================================
function figBar(style, figDir)
    df = mtcars();
    cyls = unique(df.cyl);
    means = arrayfun(@(c) mean(df.mpg(df.cyl == c)), cyls);

    fig = figure('Visible', 'off');
    ax = axes(fig);
    bar(ax, categorical(string(cyls)), means, 0.6);
    title(ax, 'Mean mileage (mpg)');
    xlabel(ax, 'Cylinders');
    figExport(fig, 'bar', style, figDir);
    close(fig);
end

% ==================================================================================
% binned scatter by group. Manual quartile-bin-and-collapse (mtcars is far
% smaller than auto.dta, so quartiles stand in for deciles) within each `am`
% group (relabeled Automatic/Manual). mono tells the groups apart by marker
% fill (filled vs. hollow circle) since there is no color to lean on; color
% uses MATLAB's default color order.
% ==================================================================================
function figBinscatter(style, figDir)
    df = mtcars();
    labels = {'Automatic', 'Manual'};
    amVals = [0 1];
    defaultColors = get(groot, 'DefaultAxesColorOrder');

    fig = figure('Visible', 'off');
    ax = axes(fig);
    hold(ax, 'on');
    for k = 1:2
        sub = df(df.am == amVals(k), :);
        bins = discretize(sub.wt, quantile(sub.wt, 0:0.25:1));
        binnedWt = arrayfun(@(b) mean(sub.wt(bins == b)), 1:4);
        binnedMpg = arrayfun(@(b) mean(sub.mpg(bins == b)), 1:4);
        if strcmp(style.suffix, 'mono')
            markerColor = [0.15 0.15 0.15];
            faceColor = 'none';
            if k == 1; faceColor = markerColor; end
        else
            markerColor = defaultColors(k, :);
            faceColor = markerColor;
        end
        scatter(ax, binnedWt, binnedMpg, 60, 'MarkerFaceColor', faceColor, ...
            'MarkerEdgeColor', markerColor, 'LineWidth', 1.4, ...
            'DisplayName', labels{k});
    end
    hold(ax, 'off');
    legend(ax, 'Location', 'northeast');
    title(ax, 'Mileage (mpg)');
    xlabel(ax, 'Weight (lbs, thousands)');
    figExport(fig, 'binscatter', style, figDir);
    close(fig);
end

% ==================================================================================
% kernel-density overlay by group. mono tells densities apart by linestyle
% (solid vs. dashed) since there is no color to lean on.
% ==================================================================================
function figKdensity(style, figDir)
    df = mtcars();
    labels = {'Automatic', 'Manual'};
    amVals = [0 1];
    lineStyles = {'-', '--'};
    defaultColors = get(groot, 'DefaultAxesColorOrder');
    grid = linspace(min(df.mpg) - 5, max(df.mpg) + 5, 200);

    fig = figure('Visible', 'off');
    ax = axes(fig);
    hold(ax, 'on');
    for k = 1:2
        x = df.mpg(df.am == amVals(k));
        density = ksdensity(x, grid);
        if strcmp(style.suffix, 'mono')
            plot(ax, grid, density, 'Color', [0.15 0.15 0.15], 'LineStyle', lineStyles{k}, ...
                'LineWidth', 1.8, 'DisplayName', labels{k});
        else
            plot(ax, grid, density, 'Color', defaultColors(k, :), ...
                'LineWidth', 1.8, 'DisplayName', labels{k});
        end
    end
    hold(ax, 'off');
    legend(ax, 'Location', 'northeast');
    title(ax, 'Density');
    xlabel(ax, 'Mileage (mpg)');
    figExport(fig, 'kdensity', style, figDir);
    close(fig);
end

% ==================================================================================
% histogram + kdensity overlay by group. Like figKdensity, but with translucent
% histogram fill shown behind each density line.
% ==================================================================================
function figHistogramOverlap(style, figDir)
    df = mtcars();
    edges = (min(df.mpg) - 3):3:(max(df.mpg) + 3);
    grid = linspace(min(df.mpg) - 5, max(df.mpg) + 5, 200);
    labels = {'Automatic', 'Manual'};
    amVals = [0 1];
    defaultColors = get(groot, 'DefaultAxesColorOrder');

    fig = figure('Visible', 'off');
    ax = axes(fig);
    hold(ax, 'on');
    for k = 1:2
        x = df.mpg(df.am == amVals(k));
        if strcmp(style.suffix, 'mono')
            col = [0.15 0.15 0.15] * k / 2 + [0.5 0.5 0.5] * (1 - k / 2);
        else
            col = defaultColors(k, :);
        end
        histogram(ax, x, edges, 'Normalization', 'pdf', 'FaceColor', col, ...
            'FaceAlpha', 0.3, 'EdgeColor', col, 'LineWidth', 1.2, ...
            'DisplayName', labels{k});
        density = ksdensity(x, grid);
        plot(ax, grid, density, 'Color', col, 'LineWidth', 1.8, 'HandleVisibility', 'off');
    end
    hold(ax, 'off');
    legend(ax, 'Location', 'northeast');
    title(ax, 'Density');
    xlabel(ax, 'Mileage (mpg)');
    figExport(fig, 'histogram_overlap', style, figDir);
    close(fig);
end
