%% Solar Tracker Control Simulation - step by step
% This file is split into sections. Open it in the MATLAB Editor and press
% Ctrl+Enter (Run Section) on the section you want to run; the output appears
% as it would in a notebook. Use "Run" to execute every section in order.
%
% Section 1 must be run once per MATLAB session. After that, any section can
% be run on its own.
%
% See also RUN_EVERYTHING, RUN_ALL_TESTS.

% AI-assisted: section layout drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-12.

%% 1. Setup - folder, path, environment
projectRoot = fileparts(mfilename('fullpath'));
cd(projectRoot);
addpath(genpath(fullfile(projectRoot, 'src')));
addpath(genpath(fullfile(projectRoot, 'tests')));
addpath(fullfile(projectRoot, 'models'));

check_environment();

%% 2. Configuration - parameters and SDI preference
run(fullfile(projectRoot, 'src', 'initialization', 'setup_project.m'));
cfg = project_config();
configure_sdi_preferences();

fprintf('Site: %s (%.4f, %.4f), UTC+%g\n', cfg.site.name, ...
    cfg.site.latitude, cfg.site.longitude, cfg.site.timeZone);

%% 3. Build both models from their build scripts
baselineModel = build_solar_tracker_model();
plantModel = build_tracker_plant_model();

fprintf('\nBaseline model : %s\n', baselineModel);
fprintf('Plant model    : %s\n', plantModel);

%% 4. Axis plant verification - closed-form checks (4)
verify_axis_plant();

%% 5. Closed-loop plant validation - step and tracking checks (14)
results = validate_tracker_plant();
failed = results(~results.Pass, :);
assert(isempty(failed), '%d plant check(s) failed.', height(failed));

%% 6. Baseline simulation - 24 hours, writes metrics and figure
[simOut, metrics] = run_project();
disp(metrics)

%% 7. Daily energy comparison - fixed, single-axis, dual-axis
daily = compare_daily_energy('SampleTimeMinutes', 20);
disp(daily)

%% 8. Annual axis comparison - full year, three configurations
annual = compare_tracker_axes();
disp(annual)

%% 9. Actuator sizing - torque, current, voltage, speed
sizing = design_sizing(cfg, 'Verbose', false);
fprintf('\nAzimuth  : output torque %.2f N*m, current %.2f A\n', ...
    sizing.azimuth.outputTorque, sizing.azimuth.current);
fprintf('Elevation: output torque %.2f N*m, current %.2f A\n', ...
    sizing.elevation.outputTorque, sizing.elevation.current);

%% 10. Unit tests - 50 cases across six files
unitResults = run_unit_tests();
passed = nnz([unitResults.Passed]);
fprintf('\n%d of %d unit tests passed.\n', passed, numel(unitResults));
assert(passed == numel(unitResults), 'Some unit tests failed.');

%% 11. Full test suite - seven stages, including the annual analysis
run_all_tests('IncludeAnalysis', true);

%% 12. Everything at once - same as the one-command entry point
% Running this section repeats the steps above. It is here so that the file
% can also be used as a single click check of the whole project.
run_everything();
