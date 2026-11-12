function results = validate_tracker_plant(options)
% VALIDATE_TRACKER_PLANT  Close the loop around the explicit axis plants.
%
%   RESULTS = VALIDATE_TRACKER_PLANT() runs two scenarios on
%   models/solar_tracker_plant.slx and returns one table of measurements with
%   their pass criteria.
%
%   Scenario 1 - step response. Both axes start at 0 deg and are commanded to
%   30 deg azimuth and 45 deg tilt. The scenario measures rise time,
%   overshoot, settling time, steady-state error, and peak armature current.
%   This is the axis-controller validation required by the project brief.
%
%   Scenario 2 - solar tracking. The model follows the real solar trajectory
%   for a two-hour window on the configured day. The first 60 s are an
%   alignment period, because the panel starts horizontal; tracking metrics
%   are computed after that. The two-hour window keeps the run affordable:
%   the fixed control step is 10 ms, so a full day would need 8.6 million
%   steps. The daily energy study stays on the reduced-order model.
%
%   RESULTS = VALIDATE_TRACKER_PLANT(Name, Value) configures the run:
%       WriteFiles      write CSV and figure (default true)
%       ShowPlots       display the figure (default false)
%       Rebuild         rebuild the model before running (default false)
%       AlignmentTime   tracking alignment period in seconds (default 60)
%
%   The function throws validate_tracker_plant:Failed when any criterion is
%   not met.
%
%   See also BUILD_TRACKER_PLANT_MODEL, VERIFY_AXIS_PLANT, RUN_PROJECT.

% AI-assisted: scenario design and metric checks drafted with
% OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-11.

arguments
    options.WriteFiles (1, 1) logical = true
    options.ShowPlots (1, 1) logical = false
    options.Rebuild (1, 1) logical = false
    options.AlignmentTime (1, 1) double = 60
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(projectRoot, 'src')));
addpath(fullfile(projectRoot, 'models'));
run(fullfile(projectRoot, 'src', 'initialization', 'setup_project.m'));

modelName = 'solar_tracker_plant';
modelFile = fullfile(projectRoot, 'models', [modelName '.slx']);

if options.Rebuild || ~isfile(modelFile)
    build_tracker_plant_model();
end

cfg = project_config();

%% Scenario 1: step response through the plant.
stepEnd = 40;
stepOutput = run_scenario(modelName, ...
    timeseries([30; 30], [0; stepEnd]), ...
    timeseries([45; 45], [0; stepEnd]), stepEnd);

stepRows = step_metrics(stepOutput, cfg);

%% Scenario 2: two hours of solar tracking.
windowStart = datetime(2026, 3, 21, 8, 0, 0);
windowHours = 2;
time = windowStart + minutes(0:cfg.analysis.timeStepMinutes:windowHours * 60);
sun = solar_position(time, cfg.site.latitude, cfg.site.longitude, ...
    cfg.site.timeZone);
target = target_angles(sun, ...
    'minAzimuth', cfg.tracker.azimuth.minAngle, ...
    'maxAzimuth', cfg.tracker.azimuth.maxAngle, ...
    'minTilt', cfg.tracker.elevation.minAngle, ...
    'maxTilt', cfg.tracker.elevation.maxAngle, ...
    'stowAzimuth', cfg.tracker.azimuth.stowAngle, ...
    'stowTilt', cfg.tracker.elevation.stowAngle);
trajectoryTime = seconds(time - time(1));
windowEnd = trajectoryTime(end);

% The panel starts horizontal. A real tracker homes to the sun before it
% starts tracking, so the target is ramped from the initial position to the
% first commanded angle during the alignment period. Tracking metrics are
% evaluated after that, so the homing move does not flatter the result.
targetAzimuth = vertcat(target.azimuth);
targetTilt = vertcat(target.tilt);
homingTime = [0; options.AlignmentTime; trajectoryTime(2:end)'];
homingAzimuth = [0; targetAzimuth(1); targetAzimuth(2:end)];
homingTilt = [0; targetTilt(1); targetTilt(2:end)];

trackOutput = run_scenario(modelName, ...
    timeseries(homingAzimuth, homingTime), ...
    timeseries(homingTilt, homingTime), windowEnd);

trackRows = tracking_metrics(trackOutput, target, time, ...
    options.AlignmentTime);

results = [stepRows; trackRows];
results.Properties.Description = 'Closed-loop validation on the Simscape axis plant';

%% Report.
fprintf('\nTracker plant validation\n');
fprintf('%s\n', repmat('-', 1, 84));
fprintf('%-26s %-14s %10s %-12s %s\n', ...
    'METRIC', 'SCENARIO', 'VALUE', 'CRITERION', 'RESULT');
fprintf('%s\n', repmat('-', 1, 84));
for k = 1:height(results)
    if results.Pass(k)
        verdict = 'pass';
    else
        verdict = 'FAIL';
    end
    fprintf('%-26s %-14s %10.4f %-12s %s\n', ...
        results.Metric(k), results.Scenario(k), results.Value(k), ...
        results.Criterion(k), verdict);
end
fprintf('%s\n', repmat('-', 1, 84));

failed = results(~results.Pass, :);
fprintf('%d of %d checks passed.\n', height(results) - height(failed), ...
    height(results));

if options.WriteFiles
    metricsDir = fullfile(projectRoot, 'results', 'metrics');
    figuresDir = fullfile(projectRoot, 'results', 'figures');
    if ~isfolder(metricsDir)
        mkdir(metricsDir);
    end
    if ~isfolder(figuresDir)
        mkdir(figuresDir);
    end
    metricsFile = fullfile(metricsDir, 'plant_validation.csv');
    writetable(results(:, {'Scenario', 'Metric', 'Value', 'Unit', ...
        'Criterion', 'Pass'}), metricsFile);
    fprintf('Metrics written : %s\n', metricsFile);

    fig = plot_validation(stepOutput, trackOutput, time, target);
    figureFile = fullfile(figuresDir, 'plant_validation.png');
    exportgraphics(fig, figureFile, 'Resolution', 150);
    fprintf('Figure written  : %s\n', figureFile);
    if ~options.ShowPlots
        close(fig);
    end
elseif options.ShowPlots
    plot_validation(stepOutput, trackOutput, time, target);
end

if ~isempty(failed)
    error('validate_tracker_plant:Failed', ...
        'Failed check(s): %s', strjoin(failed.Metric, ', '));
end
end

% -------------------------------------------------------------------------

function output = run_scenario(modelName, azimuthInput, tiltInput, stopTime)
% Load the model, install the target signals, and simulate.
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
load_system([modelName '.slx']);

modelWorkspace = get_param(modelName, 'ModelWorkspace');
assignin(modelWorkspace, 'targetAzimuthInput', azimuthInput);
assignin(modelWorkspace, 'targetTiltInput', tiltInput);
set_param(modelName, 'StopTime', num2str(stopTime));

simOut = sim(modelName, 'ReturnWorkspaceOutputs', 'on');
yout = simOut.get('yout');
set_param(modelName, 'Dirty', 'off');

output.azimuth = signal(yout, 1);
output.tilt = signal(yout, 2);
output.azimuthError = signal(yout, 3);
output.tiltError = signal(yout, 4);
output.azimuthCurrent = signal(yout, 5);
output.tiltCurrent = signal(yout, 6);
end

function data = signal(yout, index)
% The Dataset element stores a timeseries in this model configuration.
element = yout.getElement(index).Values;
data.Time = element.Time;
data.Data = element.Data;
end

function rows = step_metrics(out, cfg)
axes = {'azimuth', 'tilt'};
references = [30, 45];
limits = [cfg.actuator.azimuth.currentLimit, cfg.actuator.elevation.currentLimit];

blocks = cell(numel(axes), 1);
for k = 1:numel(axes)
    name = axes{k};
    angle = out.(name);
    reference = references(k);

    riseTime = local_rise_time(angle.Data, angle.Time, reference);
    overshoot = 100 * (max(angle.Data) - reference) / reference;
    settleTime = local_settle_time(angle.Data, angle.Time, reference);
    steadyState = abs(angle.Data(end) - reference);
    peakCurrent = max(abs(out.([name 'Current']).Data));

    scenario = sprintf('step %s', name);
    blocks{k} = [
        local_row(scenario, 'Rise time 10-90%', riseTime, 's', '<= 10 s', riseTime <= 10)
        local_row(scenario, 'Overshoot', overshoot, '%', '<= 10 %', overshoot <= 10)
        local_row(scenario, 'Settling time 2%', settleTime, 's', '<= 20 s', settleTime <= 20)
        local_row(scenario, 'Steady-state error', steadyState, 'deg', '<= 0.2 deg', steadyState <= 0.2)
        local_row(scenario, 'Peak current', peakCurrent, 'A', ...
            sprintf('<= %.1f A', 1.02 * limits(k)), peakCurrent <= 1.02 * limits(k))];
end
rows = vertcat(blocks{:});
end

function rows = tracking_metrics(out, target, time, alignmentTime)
rows = table(strings(0, 1), strings(0, 1), zeros(0, 1), strings(0, 1), ...
    strings(0, 1), false(0, 1), 'VariableNames', ...
    {'Scenario', 'Metric', 'Value', 'Unit', 'Criterion', 'Pass'});

% Only evaluate after the panel has had time to reach the trajectory.
mask = out.azimuthError.Time >= alignmentTime;
azimuthError = out.azimuthError.Data(mask);
tiltError = out.tiltError.Data(mask);
azimuthRmse = sqrt(mean(azimuthError .^ 2));
tiltRmse = sqrt(mean(tiltError .^ 2));
azimuthMax = max(abs(azimuthError));
tiltMax = max(abs(tiltError));

rows = [rows
    local_row('tracking', 'Azimuth RMSE', azimuthRmse, 'deg', '<= 0.5 deg', azimuthRmse <= 0.5)
    local_row('tracking', 'Tilt RMSE', tiltRmse, 'deg', '<= 0.5 deg', tiltRmse <= 0.5)
    local_row('tracking', 'Azimuth max error', azimuthMax, 'deg', '<= 2.0 deg', azimuthMax <= 2.0)
    local_row('tracking', 'Tilt max error', tiltMax, 'deg', '<= 2.0 deg', tiltMax <= 2.0)];

% Guard against a silently empty or misaligned window.
if numel(target) ~= numel(time)
    rows = [rows
        local_row('tracking', 'Target samples', numel(target), 'samples', ...
            'matches time vector', false)];
end
end

function row = local_row(scenario, metric, value, unit, criterion, pass)
row = table(string(scenario), string(metric), value, string(unit), ...
    string(criterion), logical(pass), 'VariableNames', ...
    {'Scenario', 'Metric', 'Value', 'Unit', 'Criterion', 'Pass'});
end

function t = local_rise_time(y, time, reference)
low = find(y >= 0.1 * reference, 1, 'first');
high = find(y >= 0.9 * reference, 1, 'first');
if isempty(low) || isempty(high)
    t = NaN;
else
    t = time(high) - time(low);
end
end

function t = local_settle_time(y, time, reference)
band = 0.02 * reference;
outside = find(abs(y - reference) > band, 1, 'last');
if isempty(outside)
    t = 0;
elseif outside == numel(y)
    t = NaN;
else
    t = time(outside + 1);
end
end

function fig = plot_validation(stepOutput, trackOutput, time, target)
fig = figure('Name', 'Tracker Plant Validation', 'Color', 'w');
tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
plot(stepOutput.azimuth.Time, stepOutput.azimuth.Data, 'LineWidth', 1.2);
hold on;
yline(30, '--');
grid on;
ylabel('Azimuth (deg)');
xlabel('Time (s)');
title('Step response, azimuth');
legend('Simulated', 'Target', 'Location', 'best');

nexttile;
plot(stepOutput.tilt.Time, stepOutput.tilt.Data, 'LineWidth', 1.2);
hold on;
yline(45, '--');
grid on;
ylabel('Tilt (deg)');
xlabel('Time (s)');
title('Step response, tilt');
legend('Simulated', 'Target', 'Location', 'best');

nexttile;
hours = seconds(time - time(1)) / 3600;
plot(hours, vertcat(target.azimuth), '--', 'LineWidth', 1.2);
hold on;
plot(trackOutput.azimuth.Time / 3600, trackOutput.azimuth.Data, 'LineWidth', 1.2);
grid on;
ylabel('Azimuth (deg)');
xlabel('Time (h)');
title('Tracking, azimuth');
legend('Target', 'Simulated', 'Location', 'best');

nexttile;
plot(hours, vertcat(target.tilt), '--', 'LineWidth', 1.2);
hold on;
plot(trackOutput.tilt.Time / 3600, trackOutput.tilt.Data, 'LineWidth', 1.2);
grid on;
ylabel('Tilt (deg)');
xlabel('Time (h)');
title('Tracking, tilt');
legend('Target', 'Simulated', 'Location', 'best');
end
