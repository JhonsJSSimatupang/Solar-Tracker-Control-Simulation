function summary = run_all_tests(options)
% RUN_ALL_TESTS  Run every test level and print one pass/fail summary.
%
%   SUMMARY = RUN_ALL_TESTS() runs the environment check, the unit suite, the
%   axis plant verification, the integration simulation, and the actuator
%   sizing check, then prints a single table. A stage that cannot run on this
%   installation is reported as skipped, not failed.
%
%   SUMMARY = RUN_ALL_TESTS(Name, Value) configures the run:
%       IncludePlant           verify the Simscape axis plant (default true)
%       IncludeValidation      run the closed-loop plant validation (default true)
%       IncludeAnalysis        run the annual axis comparison (default false)
%       CheckReproducibility   simulate twice and compare (default true)
%       WriteReport            write JUnit XML and a summary CSV (default true)
%
%   The function throws an error if any stage fails, so it works as a single
%   gate in a batch run:
%
%       matlab -batch "run_all_tests"
%
%   Example:
%       summary = run_all_tests('CheckReproducibility', false);
%       disp(struct2table(summary))
%
%   The integration stage compares its metrics with the values already stored
%   in results/metrics/tracking_metrics.csv. That file is the regression
%   baseline: it is only rewritten by run_project, and this function always
%   simulates with WriteFiles set to false.
%
%   See also RUN_PROJECT, VERIFY_AXIS_PLANT, CHECK_ENVIRONMENT.

% AI-assisted: runner structure and stage design drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-11.

arguments
    options.IncludePlant (1, 1) logical = true
    options.IncludeValidation (1, 1) logical = true
    options.IncludeAnalysis (1, 1) logical = false
    options.CheckReproducibility (1, 1) logical = true
    options.WriteReport (1, 1) logical = true
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(projectRoot, 'src')));
addpath(genpath(fullfile(projectRoot, 'tests')));
addpath(fullfile(projectRoot, 'models'));

% The SDI copy of every run is unused, and on a low-disk host SDI can switch
% logging off in the middle of a simulation. Turn it off before any stage runs.
configure_sdi_preferences();

reportDir = fullfile(projectRoot, 'results', 'test-reports');
if options.WriteReport && ~isfolder(reportDir)
    mkdir(reportDir);
end

summary = struct('stage', {}, 'status', {}, 'detail', {});

fprintf('\n============================================================\n');
fprintf(' Solar Tracker Control Simulation - full test run\n');
fprintf('============================================================\n');

%% Stage 1: environment
fprintf('\n--- Stage 1: environment ---\n');
env = check_environment();
[status, detail] = localEnvironmentStatus(env);
summary = localAdd(summary, "environment", status, detail);

%% Stage 2: unit suite
fprintf('\n--- Stage 2: unit suite ---\n');
[status, detail] = localRunUnitSuite(projectRoot, options.WriteReport, reportDir);
summary = localAdd(summary, "unit suite", status, detail);

%% Stage 3: axis plant
if options.IncludePlant
    fprintf('\n--- Stage 3: axis plant ---\n');
    [status, detail] = localVerifyPlant();
    summary = localAdd(summary, "axis plant", status, detail);
end

%% Stage 4: closed-loop plant validation
if options.IncludeValidation
    fprintf('\n--- Stage 4: plant validation ---\n');
    [status, detail] = localValidatePlant();
    summary = localAdd(summary, "plant validation", status, detail);
end

%% Stage 5: integration
fprintf('\n--- Stage 5: integration ---\n');
[status, detail] = localIntegration(projectRoot, options.CheckReproducibility);
summary = localAdd(summary, "integration", status, detail);

%% Stage 6: actuator sizing
fprintf('\n--- Stage 6: actuator sizing ---\n');
[status, detail] = localSizing();
summary = localAdd(summary, "actuator sizing", status, detail);

%% Stage 7: annual analysis (optional, slow)
if options.IncludeAnalysis
    fprintf('\n--- Stage 7: annual analysis ---\n');
    [status, detail] = localAnalysis();
    summary = localAdd(summary, "annual analysis", status, detail);
end

%% Report
fprintf('\n============================================================\n');
fprintf(' SUMMARY\n');
fprintf('============================================================\n');
fprintf('%-20s %-7s %s\n', 'STAGE', 'RESULT', 'DETAIL');
fprintf('%s\n', repmat('-', 1, 78));
for k = 1:numel(summary)
    fprintf('%-20s %-7s %s\n', summary(k).stage, ...
        upper(summary(k).status), summary(k).detail);
end
fprintf('%s\n', repmat('-', 1, 78));

if options.WriteReport
    summaryFile = fullfile(reportDir, 'test_summary.csv');
    writetable(struct2table(summary), summaryFile);
    fprintf('Summary written : %s\n', summaryFile);
end

failed = summary(strcmp({summary.status}, 'fail'));
skipped = summary(strcmp({summary.status}, 'skip'));
fprintf('%d stage(s) passed, %d failed, %d skipped.\n\n', ...
    numel(summary) - numel(failed) - numel(skipped), ...
    numel(failed), numel(skipped));

if ~isempty(failed)
    error('run_all_tests:Failed', 'Failed stage(s): %s', ...
        strjoin(string({failed.stage}), ', '));
end
end

% -------------------------------------------------------------------------

function summary = localAdd(summary, stage, status, detail)
summary(end + 1) = struct('stage', stage, 'status', status, 'detail', detail);
end

function [status, detail] = localEnvironmentStatus(env)
core = ["MATLAB", "Simulink"];
missingCore = env.MissingRequired(ismember(env.MissingRequired, core));
if ~isempty(missingCore)
    status = 'fail';
    detail = sprintf('missing core product(s): %s', strjoin(missingCore, ', '));
elseif isempty(env.MissingRequired)
    status = 'pass';
    detail = 'all required products installed';
else
    % MATLAB and Simulink are present, so the code-level stages can run.
    status = 'pass';
    detail = sprintf('core products present; not installed: %s', ...
        strjoin(env.MissingRequired, ', '));
end
end

function [status, detail] = localRunUnitSuite(projectRoot, writeReport, reportDir)
suite = testsuite(fullfile(projectRoot, 'tests', 'unit'));
runner = matlab.unittest.TestRunner.withTextOutput('Verbosity', 1);
reportNote = "";
if writeReport
    reportNote = localAddReportPlugin(runner, reportDir);
end
results = runner.run(suite);

numPassed = nnz([results.Passed]);
numFailed = nnz([results.Failed]);
numIncomplete = nnz([results.Incomplete]);
total = numel(results);

if numFailed > 0 || numIncomplete > 0
    status = 'fail';
    detail = sprintf('%d/%d passed, %d failed, %d incomplete%s', ...
        numPassed, total, numFailed, numIncomplete, reportNote);
else
    status = 'pass';
    detail = sprintf('%d/%d passed%s', numPassed, total, reportNote);
end
end

function note = localAddReportPlugin(runner, reportDir)
% The JUnit XML plugin is not present in every installation: a trimmed
% MATLAB may ship without it. Add it when available and say so when not,
% rather than failing the whole suite over a reporting format.
if exist('matlab.unittest.plugins.XMLOutputPlugin', 'class') == 8
    plugin = matlab.unittest.plugins.XMLOutputPlugin(reportDir);
    runner.addPlugin(plugin);
    note = ", JUnit XML written";
else
    note = ", no XML plugin in this installation";
end
end

function [status, detail] = localVerifyPlant()
try
    verify_axis_plant();
    status = 'pass';
    detail = 'T1 steady state, T2 current ceiling, T3 rise time, T4 bus ceiling';
catch ME
    if strcmp(ME.identifier, 'verify_axis_plant:MissingSimscape')
        status = 'skip';
        detail = 'Simscape Electrical not installed';
    else
        status = 'fail';
        detail = sprintf('%s: %s', ME.identifier, ME.message);
    end
end
end

function [status, detail] = localValidatePlant()
try
    results = validate_tracker_plant('WriteFiles', false, 'ShowPlots', false);
    numPassed = nnz(results.Pass);
    status = 'pass';
    detail = sprintf(['%d/%d checks: step overshoot %.1f/%.1f %%, ' ...
        'tracking RMSE %.3f/%.3f deg'], ...
        numPassed, height(results), ...
        results.Value(strcmp(results.Metric, 'Overshoot') & ...
            contains(results.Scenario, 'azimuth')), ...
        results.Value(strcmp(results.Metric, 'Overshoot') & ...
            contains(results.Scenario, 'tilt')), ...
        results.Value(strcmp(results.Metric, 'Azimuth RMSE')), ...
        results.Value(strcmp(results.Metric, 'Tilt RMSE')));
catch ME
    if strcmp(ME.identifier, 'verify_axis_plant:MissingSimscape') || ...
            contains(ME.message, 'Simscape Electrical')
        status = 'skip';
        detail = 'Simscape Electrical not installed';
    else
        status = 'fail';
        detail = sprintf('%s: %s', ME.identifier, ME.message);
    end
end
end

function [status, detail] = localIntegration(projectRoot, checkReproducibility)
try
    [~, metrics] = run_project('ShowPlots', false, 'WriteFiles', false);
catch ME
    status = 'fail';
    detail = sprintf('simulation did not run: %s', ME.message);
    return
end

problems = strings(0, 1);

% Regression against the stored baseline, when it exists.
baselineFile = fullfile(projectRoot, 'results', 'metrics', 'tracking_metrics.csv');
if isfile(baselineFile)
    baseline = readtable(baselineFile);
    % readtable returns the text column as a cell array of char, while the
    % metrics table uses a string array. Compare after normalising both.
    sameLabels = height(baseline) == height(metrics) && ...
        isequal(string(baseline.Metric), string(metrics.Metric));
    if sameLabels
        scale = max(abs(baseline.Value), eps);
        deviation = abs(baseline.Value - metrics.Value) ./ scale;
        worst = find(deviation > 0.01, 1);
        if ~isempty(worst)
            problems(end + 1) = sprintf( ...
                '%s deviates %.2f%% from baseline', ...
                metrics.Metric(worst), 100 * deviation(worst));
        end
    else
        problems(end + 1) = "baseline table has a different shape";
    end
end

% FR-06 internal target: RMS tracking error at or below 0.5 deg.
azimuthRmse = metrics.Value(1);
tiltRmse = metrics.Value(2);
if azimuthRmse > 0.5 || tiltRmse > 0.5
    problems(end + 1) = sprintf( ...
        'RMSE %.3f/%.3f deg exceeds the 0.5 deg target', ...
        azimuthRmse, tiltRmse);
end

% Reproducibility: a fixed-step solver must give the same numbers twice.
if checkReproducibility
    try
        [~, second] = run_project('ShowPlots', false, 'WriteFiles', false);
        if ~isequaln(metrics.Value, second.Value)
            problems(end + 1) = "two consecutive runs differ";
        end
    catch ME
        problems(end + 1) = sprintf('second run failed: %s', ME.message);
    end
end

if isempty(problems)
    status = 'pass';
    detail = sprintf('RMSE %.4f/%.4f deg, stable across runs', ...
        azimuthRmse, tiltRmse);
else
    status = 'fail';
    detail = strjoin(problems, '; ');
end
end

function [status, detail] = localSizing()
try
    cfg = project_config();
    sizing = design_sizing(cfg, 'Verbose', false);
catch ME
    status = 'fail';
    detail = sprintf('sizing did not run: %s', ME.message);
    return
end

% Ratios must exceed 1; absolute margins must stay positive.
torqueMargin = [sizing.azimuth.torqueMargin, sizing.elevation.torqueMargin];
speedMargin = [sizing.azimuth.speedMargin, sizing.elevation.speedMargin];
currentMargin = [sizing.azimuth.currentMargin, sizing.elevation.currentMargin];
voltageMargin = [sizing.azimuth.voltageMargin, sizing.elevation.voltageMargin];

bad = find(torqueMargin <= 1 | speedMargin <= 1 | ...
    currentMargin <= 0 | voltageMargin <= 0, 1);

if isempty(bad)
    status = 'pass';
    detail = sprintf('torque %.2f/%.2f, speed %.2f/%.2f, current %.2f/%.2f A', ...
        torqueMargin(1), torqueMargin(2), speedMargin(1), speedMargin(2), ...
        currentMargin(1), currentMargin(2));
else
    axisName = ["azimuth", "elevation"];
    status = 'fail';
    detail = sprintf(['%s axis margin too small: torque %.2f, speed %.2f, ' ...
        'current %.2f A, voltage %.2f V'], axisName(bad), ...
        torqueMargin(bad), speedMargin(bad), currentMargin(bad), voltageMargin(bad));
end
end

function [status, detail] = localAnalysis()
try
    results = compare_tracker_axes();
catch ME
    status = 'fail';
    detail = sprintf('analysis did not run: %s', ME.message);
    return
end

% Expected ordering: fixed <= azimuth <= horizontal N-S <= dual-axis.
energy = results.Energy_kWh_per_m2;
if all(diff(energy) >= -1e-6)
    status = 'pass';
    detail = sprintf('annual %.0f/%.0f/%.0f/%.0f kWh/m^2, ordering holds', ...
        energy(1), energy(2), energy(3), energy(4));
else
    status = 'fail';
    detail = sprintf('annual ordering violated: %s', ...
        mat2str(round(energy', 1)));
end
end
