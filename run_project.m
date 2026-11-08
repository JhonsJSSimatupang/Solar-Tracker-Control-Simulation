function run_project()
% RUN_PROJECT  One-click entry point for the Solar Tracker Control Simulation.
%
%   RUN_PROJECT adds the project source folders to the MATLAB path, loads the
%   project parameters, and runs the main Simulink model. Use this function as
%   the single entry point for reproducing the simulation results.
%
%   See also SETUP_PROJECT, SOLAR_TRACKER.

% Project root is the folder that contains this file.
projectRoot = fileparts(mfilename('fullpath'));

% Make project source code available to MATLAB.
addpath(genpath(fullfile(projectRoot, 'src')));

% Load simulation parameters.
setupFile = fullfile(projectRoot, 'src', 'initialization', 'setup_project.m');
if isfile(setupFile)
    run(setupFile);
else
    warning('run_project:MissingSetup', ...
        'Parameter setup file not found: %s', setupFile);
end

% Run the main Simulink model.
modelName = 'solar_tracker';
modelFile = fullfile(projectRoot, 'models', [modelName '.slx']);
if isfile(modelFile)
    load_system(modelFile);
    simOut = sim(modelName);
    assignin('base', 'simOut', simOut);
else
    fprintf('Main model not found: %s\n', modelFile);
    fprintf('Add the Simulink model under models/ and run run_project again.\n');
end
end
