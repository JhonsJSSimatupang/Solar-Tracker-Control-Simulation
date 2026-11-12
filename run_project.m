function [simOut, metrics] = run_project(options)
% RUN_PROJECT  One-click entry point for the Solar Tracker Control Simulation.
%
%   RUN_PROJECT adds the project source folders to the MATLAB path, loads the
%   project parameters, builds the solar target trajectory for the configured
%   day, runs the main Simulink model, and displays the tracking response.
%
%   [SIMOUT, METRICS] = RUN_PROJECT(...) also returns the simulation output and
%   a table with the tracking error metrics. Use this function as the single
%   entry point for reproducing the simulation results.
%
%   RUN_PROJECT(Name, Value) configures the run:
%       ShowPlots   true/false, display the response figure (default true)
%       WriteFiles  true/false, write the figure and metrics (default true)
%       StopTime    simulation stop time in seconds (default: full day)
%
%   Example:
%       run_project
%       [simOut, metrics] = run_project('ShowPlots', false);
%
%   See also SETUP_PROJECT, SOLAR_POSITION, TARGET_ANGLES, SOLAR_TRACKER.

arguments
    options.ShowPlots (1, 1) logical = true
    options.WriteFiles (1, 1) logical = true
    options.StopTime (1, 1) double = NaN
end

% Project root is the folder that contains this file.
projectRoot = fileparts(mfilename('fullpath'));

% Make project source code available to MATLAB.
addpath(genpath(fullfile(projectRoot, 'src')));
addpath(fullfile(projectRoot, 'models'));

% Load simulation parameters. setup_project also copies cfg to the base
% workspace, where the Simulink model resolves its block parameters.
setupFile = fullfile(projectRoot, 'src', 'initialization', 'setup_project.m');
if ~isfile(setupFile)
    error('run_project:MissingSetup', ...
        'Parameter setup file not found: %s', setupFile);
end
run(setupFile);

%% Build the solar target trajectory for the configured day.
time = cfg.simulation.startTime + minutes(0:cfg.analysis.timeStepMinutes:...
    cfg.simulation.durationHours * 60);
sun = solar_position(time, cfg.site.latitude, cfg.site.longitude, ...
    cfg.site.timeZone);
target = target_angles(sun, ...
    'minAzimuth', cfg.tracker.azimuth.minAngle, ...
    'maxAzimuth', cfg.tracker.azimuth.maxAngle, ...
    'minTilt', cfg.tracker.elevation.minAngle, ...
    'maxTilt', cfg.tracker.elevation.maxAngle, ...
    'stowAzimuth', cfg.tracker.azimuth.stowAngle, ...
    'stowTilt', cfg.tracker.elevation.stowAngle);

targetAzimuth = vertcat(target.azimuth);
targetTilt = vertcat(target.tilt);
trajectoryTime = seconds(time - time(1));

%% Load and configure the model.
modelName = 'solar_tracker';
modelFile = fullfile(projectRoot, 'models', [modelName '.slx']);
if ~isfile(modelFile)
    warning('run_project:MissingModel', ...
        'Main model not found: %s', modelFile);
    simOut = [];
    metrics = table();
    return
end

if bdIsLoaded(modelName)
    if strcmp(get_param(modelName, 'Dirty'), 'on')
        error('run_project:UnsavedModel', ...
            ['Model %s has unsaved changes. Save or close it before ' ...
             'running run_project.'], modelName);
    end
    close_system(modelName, 0);
end
load_system(modelFile);

modelWorkspace = get_param(modelName, 'ModelWorkspace');
assignin(modelWorkspace, 'targetAzimuthInput', ...
    timeseries(targetAzimuth, trajectoryTime));
assignin(modelWorkspace, 'targetTiltInput', ...
    timeseries(targetTilt, trajectoryTime));

stopTime = cfg.simulation.durationHours * 3600;
if ~isnan(options.StopTime)
    stopTime = options.StopTime;
end
set_param(modelName, ...
    'StopTime', num2str(stopTime), ...
    'SaveOutput', 'on', ...
    'OutputSaveName', 'yout', ...
    'SaveFormat', 'Dataset');

%% Run the simulation.
simOut = sim(modelName, 'ReturnWorkspaceOutputs', 'on');

% Writing the target inputs into the model workspace marks the model as
% changed. Without clearing the flag, a second run_project call in the same
% session would refuse to start with run_project:UnsavedModel. The workspace
% data is regenerated on every run, so nothing is lost by clearing it.
set_param(modelName, 'Dirty', 'off');

%% Extract the logged signals.
yout = simOut.get('yout');
azimuthOutput = yout.getElement(1).Values;
tiltOutput = yout.getElement(2).Values;
azimuthError = yout.getElement(3).Values;
tiltError = yout.getElement(4).Values;

%% Compute tracking metrics.
metrics = table( ...
    ["Azimuth RMSE"; "Tilt RMSE"; "Azimuth max |error|"; "Tilt max |error|"; ...
     "Samples"; "Simulated duration"], ...
    [sqrt(mean(azimuthError.Data .^ 2, 'omitnan')); ...
     sqrt(mean(tiltError.Data .^ 2, 'omitnan')); ...
     max(abs(azimuthError.Data)); ...
     max(abs(tiltError.Data)); ...
     numel(azimuthError.Data); ...
     azimuthOutput.Time(end)], ...
    ["deg"; "deg"; "deg"; "deg"; "samples"; "s"], ...
    'VariableNames', {'Metric', 'Value', 'Unit'});

fprintf('\nSolar Tracker Control Simulation\n');
fprintf('================================\n');
fprintf('Site            : %s (%.4f, %.4f), UTC%+g\n', cfg.site.name, ...
    cfg.site.latitude, cfg.site.longitude, cfg.site.timeZone);
fprintf('Start time      : %s\n', string(cfg.simulation.startTime));
fprintf('Simulated       : %.0f s (%.1f h)\n', ...
    azimuthOutput.Time(end), azimuthOutput.Time(end) / 3600);
fprintf('Azimuth RMSE    : %.4f deg\n', metrics.Value(1));
fprintf('Tilt RMSE       : %.4f deg\n', metrics.Value(2));
fprintf('Azimuth max err : %.4f deg\n', metrics.Value(3));
fprintf('Tilt max err    : %.4f deg\n', metrics.Value(4));

%% Save and display the results.
if options.WriteFiles
    metricsDir = fullfile(projectRoot, 'results', 'metrics');
    figuresDir = fullfile(projectRoot, 'results', 'figures');
    if ~isfolder(metricsDir)
        mkdir(metricsDir);
    end
    if ~isfolder(figuresDir)
        mkdir(figuresDir);
    end

    metricsFile = fullfile(metricsDir, 'tracking_metrics.csv');
    writetable(metrics, metricsFile);
    fprintf('Metrics written : %s\n', metricsFile);

    fig = plot_tracking_response(time, targetAzimuth, targetTilt, ...
        azimuthOutput, tiltOutput, azimuthError, tiltError);
    figureFile = fullfile(figuresDir, 'tracking_response.png');
    exportgraphics(fig, figureFile, 'Resolution', 150);
    fprintf('Figure written  : %s\n', figureFile);
    if ~options.ShowPlots
        close(fig);
    end
elseif options.ShowPlots
    plot_tracking_response(time, targetAzimuth, targetTilt, ...
        azimuthOutput, tiltOutput, azimuthError, tiltError);
end
end

function fig = plot_tracking_response(time, targetAzimuth, targetTilt, ...
        azimuthOutput, tiltOutput, azimuthError, tiltError)
% PLOT_TRACKING_RESPONSE  Compare the commanded and simulated axis angles.

fig = figure('Name', 'Solar Tracker Response', 'Color', 'w');
tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
targetHours = seconds(time - time(1)) / 3600;

nexttile;
plot(targetHours, targetAzimuth, '--', 'LineWidth', 1.2);
hold on;
plot(azimuthOutput.Time / 3600, azimuthOutput.Data, 'LineWidth', 1.2);
grid on;
ylabel('Azimuth (deg)');
legend('Target', 'Simulated', 'Location', 'best');
title('Azimuth response');

nexttile;
plot(targetHours, targetTilt, '--', 'LineWidth', 1.2);
hold on;
plot(tiltOutput.Time / 3600, tiltOutput.Data, 'LineWidth', 1.2);
grid on;
ylabel('Tilt (deg)');
legend('Target', 'Simulated', 'Location', 'best');
title('Tilt response');

nexttile;
plot(azimuthError.Time / 3600, azimuthError.Data, 'LineWidth', 1.2);
grid on;
ylabel('Error (deg)');
xlabel('Time (h)');
title('Azimuth error');

nexttile;
plot(tiltError.Time / 3600, tiltError.Data, 'LineWidth', 1.2);
grid on;
ylabel('Error (deg)');
xlabel('Time (h)');
title('Tilt error');
end
