function summary = run_everything(options)
% RUN_EVERYTHING  Run every executable file in the project, in dependency order.
%
%   SUMMARY = RUN_EVERYTHING() runs the environment check, every pure function
%   once with a known input, both model builders, the axis plant verification,
%   the closed-loop plant validation, the baseline simulation, both energy
%   comparisons, the unit suite, and the full seven-stage test run. Each step is
%   reported as pass or fail, and the run continues after a failure so that one
%   broken step does not hide the state of the others.
%
%   SUMMARY = RUN_EVERYTHING('FullSuite', false) skips the final call to
%   RUN_ALL_TESTS, which repeats several of the earlier steps.
%
%   The function throws an error at the end if any step failed.
%
%   Usage:
%       run_everything
%       summary = run_everything('FullSuite', false);
%
%   This takes several minutes: two model builds, a closed-loop validation, a
%   24 h simulation, and the annual comparison all run in the same session.
%
%   See also RUN_ALL_TESTS, RUN_PROJECT, VERIFY_AXIS_PLANT.

% AI-assisted: step list and smoke calls drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-12.

arguments
    options.FullSuite (1, 1) logical = true
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(projectRoot, 'src')));
addpath(genpath(fullfile(projectRoot, 'tests')));
addpath(fullfile(projectRoot, 'models'));

summary = struct('step', {}, 'status', {}, 'detail', {});

fprintf('\n============================================================\n');
fprintf(' Solar Tracker Control Simulation - run everything\n');
fprintf('============================================================\n');

summary = localStep(summary, 'environment', @localEnvironment);
summary = localStep(summary, 'initialization', @localInitialization);
summary = localStep(summary, 'sun position', @localSunPosition);
summary = localStep(summary, 'irradiance and metrics', @localIrradiance);
summary = localStep(summary, 'actuator energy', @localActuatorEnergy);
summary = localStep(summary, 'daily energy', @localDailyEnergy);
summary = localStep(summary, 'mode logic', @localModeLogic);
summary = localStep(summary, 'design sizing', @localSizing);
summary = localStep(summary, 'model build', @localBuildModels);
summary = localStep(summary, 'axis plant checks', @localVerifyPlant);
summary = localStep(summary, 'plant validation', @localValidatePlant);
summary = localStep(summary, 'baseline simulation', @localRunProject);
summary = localStep(summary, 'daily comparison', @localDailyComparison);
summary = localStep(summary, 'annual comparison', @localAnnualComparison);
summary = localStep(summary, 'unit suite', @localUnitSuite);
if options.FullSuite
    summary = localStep(summary, 'full test run', @localFullSuite);
end

fprintf('\n============================================================\n');
fprintf(' RUN EVERYTHING - SUMMARY\n');
fprintf('============================================================\n');
fprintf('%-24s %-6s %s\n', 'STEP', 'RESULT', 'DETAIL');
fprintf('%s\n', repmat('-', 1, 78));
for k = 1:numel(summary)
    fprintf('%-24s %-6s %s\n', summary(k).step, ...
        upper(summary(k).status), summary(k).detail);
end
fprintf('%s\n', repmat('-', 1, 78));

failed = summary(strcmp({summary.status}, 'fail'));
fprintf('%d step(s) passed, %d failed.\n\n', ...
    numel(summary) - numel(failed), numel(failed));

if ~isempty(failed)
    error('run_everything:Failed', 'Failed step(s): %s', ...
        strjoin(string({failed.step}), ', '));
end
end

% -------------------------------------------------------------------------

function summary = localStep(summary, name, fn)
fprintf('\n--- %s ---\n', name);
try
    detail = fn();
    summary(end + 1) = struct('step', name, 'status', 'pass', 'detail', detail);
catch ME
    summary(end + 1) = struct('step', name, 'status', 'fail', ...
        'detail', ME.message);
    fprintf('FAILED: %s\n', ME.message);
end
end

function detail = localEnvironment()
env = check_environment();
if ~isempty(env.MissingRequired)
    error('run_everything:MissingProducts', 'Missing required: %s', ...
        strjoin(env.MissingRequired, ', '));
end
detail = 'all required products installed';
end

function detail = localInitialization()
projectRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(projectRoot, 'src', 'initialization', 'setup_project.m'));
cfg = project_config(); %#ok<NASGU>
configure_sdi_preferences();
detail = 'configuration loaded, SDI archiving off';
end

function detail = localSunPosition()
cfg = project_config();
t = cfg.simulation.startTime + hours(12);
sun = solar_position(t, cfg.site.latitude, cfg.site.longitude, ...
    cfg.site.timeZone);
target = target_angles(sun);

% The supporting functions are called so that every file is exercised, and
% their results are checked against each other: the panel normal and the
% incidence angle must agree when the panel points at the sun.
normal = panel_normal(sun.azimuth, 90 - sun.elevation);
vector = solar_vector(sun.azimuth, sun.elevation);
angle = angle_of_incidence(sun.azimuth, sun.elevation, ...
    sun.azimuth, 90 - sun.elevation);

if abs(dot(normal, vector) - 1) > 1e-9
    error('run_everything:NormalMismatch', ...
        'Panel normal does not align with the sun vector.');
end
if abs(angle) > 1e-9
    error('run_everything:IncidenceMismatch', ...
        'Incidence angle is not zero when the panel faces the sun.');
end
detail = sprintf('az %.2f deg, tilt %.2f deg', target.azimuth, target.tilt);
end

function detail = localIrradiance()
cfg = project_config();
t = cfg.simulation.startTime + hours(12);
sun = solar_position(t, cfg.site.latitude, cfg.site.longitude, ...
    cfg.site.timeZone);
irr = clear_sky_irradiance(sun.elevation);
poa = plane_of_array_irradiance(sun.azimuth, sun.elevation, ...
    sun.azimuth, 90 - sun.elevation, irr);
metrics = energy_metrics(0:3600:7200, [0 1 0], [0 100 0]);
% A panel that faces the sun receives the full direct beam plus part of the
% diffuse and ground-reflected light, so its POA irradiance cannot be below
% the direct normal irradiance.
if poa < irr.dni - 1e-9
    error('run_everything:PoaMismatch', ...
        'Sun-facing POA irradiance is below the direct normal value.');
end
if abs(metrics.netEnergy_kWh - 0.9) > 1e-9
    error('run_everything:MetricsMismatch', 'Unexpected energy integral.');
end
detail = sprintf('DNI %.2f kW/m2, net %.3f kWh', irr.dni, ...
    metrics.netEnergy_kWh);
end

function detail = localActuatorEnergy()
cfg = project_config();
params = localActuatorParameters(cfg);
time = cfg.simulation.startTime + minutes(0:10);
power = tracker_actuator_energy(time, zeros(1, 11), zeros(1, 11), params);
if any(power < 0) || any(~isfinite(power))
    error('run_everything:ActuatorPower', 'Actuator power is not physical.');
end
detail = sprintf('holding draw %.2f W', power(1));
end

function detail = localDailyEnergy()
day = daily_energy_simulation('SampleTimeMinutes', 10);
if day.pvEnergy_kWh <= 0
    error('run_everything:DailyEnergy', 'Daily PV energy is not positive.');
end
detail = sprintf('%.3f kWh PV, %.3f kWh net', day.pvEnergy_kWh, ...
    day.netEnergy_kWh);
end

function detail = localModeLogic()
cfg = project_config();
t = cfg.simulation.startTime + hours(12);
sun = solar_position(t, cfg.site.latitude, cfg.site.longitude, ...
    cfg.site.timeZone);
sunPoint = struct('azimuth', sun.azimuth, 'elevation', sun.elevation);
measured = struct('azimuth', 0, 'tilt', 0);
command = tracker_mode_logic([], sunPoint, measured);
if ~strcmp(command.mode, 'DAY_TRACK')
    error('run_everything:ModeLogic', 'Expected DAY_TRACK, got %s.', ...
        command.mode);
end
detail = 'sun up, mode DAY_TRACK';
end

function detail = localSizing()
cfg = project_config();
sizing = design_sizing(cfg, 'Verbose', false);
if sizing.azimuth.current > cfg.actuator.azimuth.currentLimit || ...
        sizing.elevation.current > cfg.actuator.elevation.currentLimit
    error('run_everything:Sizing', 'Required current exceeds the limit.');
end
detail = sprintf('output torque %.2f / %.2f N*m', ...
    sizing.azimuth.outputTorque, sizing.elevation.outputTorque);
end

function detail = localBuildModels()
baselinePath = build_solar_tracker_model();
plantPath = build_tracker_plant_model();
if ~isfile(baselinePath) || ~isfile(plantPath)
    error('run_everything:Build', 'A model file was not written.');
end
detail = 'solar_tracker.slx and solar_tracker_plant.slx rebuilt';
end

function detail = localVerifyPlant()
verify_axis_plant();
detail = 'T1 to T4 pass';
end

function detail = localValidatePlant()
results = validate_tracker_plant();
failed = results(~results.Pass, :);
if ~isempty(failed)
    error('run_everything:Validation', '%d plant check(s) failed.', ...
        height(failed));
end
detail = sprintf('%d of %d checks pass', height(results), height(results));
end

function detail = localRunProject()
[~, metrics] = run_project();
detail = sprintf('azimuth RMSE %.4f deg, tilt RMSE %.4f deg', ...
    metrics.Value(1), metrics.Value(2));
end

function detail = localDailyComparison()
results = compare_daily_energy('SampleTimeMinutes', 20);
detail = sprintf('net gain %.1f %% for dual-axis', ...
    results.NetGain_vs_Fixed_pct(end));
end

function detail = localAnnualComparison()
results = compare_tracker_axes();
detail = sprintf('fixed %.0f, dual %.0f kWh/m2', ...
    results.Energy_kWh_per_m2(1), results.Energy_kWh_per_m2(end));
end

function detail = localUnitSuite()
results = run_unit_tests();
passed = nnz([results.Passed]);
if passed < numel(results)
    error('run_everything:UnitTests', '%d unit test(s) failed.', ...
        numel(results) - passed);
end
detail = sprintf('%d of %d unit tests pass', passed, numel(results));
end

function detail = localFullSuite()
run_all_tests('IncludeAnalysis', true);
detail = 'all stages pass';
end

function params = localActuatorParameters(cfg)
% Same parameter mapping as compare_daily_energy, kept here so that the
% smoke test does not depend on a private function of another file.
base = struct( ...
    'gearRatio', cfg.tracker.azimuth.gearRatio, ...
    'gearEfficiency', cfg.tracker.azimuth.gearEfficiency, ...
    'staticFriction', cfg.actuator.azimuth.staticFriction, ...
    'torqueConstant', cfg.actuator.azimuth.torqueConstant, ...
    'backEmfConstant', cfg.actuator.azimuth.backEmfConstant, ...
    'armatureResistance', cfg.actuator.azimuth.armatureResistance, ...
    'ratedVoltage', cfg.actuator.azimuth.ratedVoltage, ...
    'currentLimit', cfg.actuator.azimuth.currentLimit, ...
    'disturbanceTorque', cfg.tracker.windMeanTorque);

params.azimuth = base;
params.elevation = base;
params.elevation.gearRatio = cfg.tracker.elevation.gearRatio;
params.elevation.gearEfficiency = cfg.tracker.elevation.gearEfficiency;
params.elevation.staticFriction = cfg.actuator.elevation.staticFriction;
params.elevation.torqueConstant = cfg.actuator.elevation.torqueConstant;
params.elevation.backEmfConstant = cfg.actuator.elevation.backEmfConstant;
params.elevation.armatureResistance = cfg.actuator.elevation.armatureResistance;
params.elevation.ratedVoltage = cfg.actuator.elevation.ratedVoltage;
params.elevation.currentLimit = cfg.actuator.elevation.currentLimit;
params.elevation.gravityTorqueAmplitude = cfg.tracker.panel.mass * 9.81 ...
    * cfg.tracker.panel.centerOfMassOffset;
end
