function cfg = project_config()
% PROJECT_CONFIG  Return the Solar Tracker project parameter structure.
%
%   CFG = PROJECT_CONFIG() returns a struct with the project metadata, site,
%   simulation, tracker, controller, actuator, energy, weather, and analysis
%   parameters. Values marked "preliminary" are confirmed at Gate G2.
%
%   The function is called by SETUP_PROJECT, which copies CFG to the base
%   workspace for Simulink.
%
%   See also SETUP_PROJECT, RUN_PROJECT.

% AI-assisted: parameter structure drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

% Project metadata
cfg.projectName = 'Solar Tracker Control Simulation';
cfg.projectId = 249;
cfg.projectVersion = '0.1.0';

% Project paths. project_config.m lives in <root>/src/initialization.
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
cfg.paths.root = projectRoot;
cfg.paths.models = fullfile(projectRoot, 'models');
cfg.paths.data = fullfile(projectRoot, 'data');
cfg.paths.results = fullfile(projectRoot, 'results');
cfg.paths.figures = fullfile(cfg.paths.results, 'figures');
cfg.paths.metrics = fullfile(cfg.paths.results, 'metrics');

% Installation site (default: Malang, Indonesia)
% Update the coordinates if the selected site changes.
cfg.site.name = 'Malang';
cfg.site.latitude = -7.9666;   % degrees, north positive
cfg.site.longitude = 112.6326; % degrees, east positive
cfg.site.timeZone = 7;         % UTC+7

% Simulation settings
cfg.simulation.startTime = datetime(2026, 3, 21, 0, 0, 0);
cfg.simulation.durationHours = 24;
cfg.simulation.controllerSampleTime = 0.01; % s
cfg.simulation.energySampleTime = 1;        % s
cfg.simulation.fullDaySolverStep = 0.1;      % s, preliminary for 24 h runs
cfg.simulation.solver = 'ode4';              % preliminary fixed-step solver
cfg.simulation.sampleTime = cfg.simulation.energySampleTime; % legacy alias

% Tracker geometry and limits
cfg.tracker.type = 'dual-axis';
cfg.tracker.azimuth.minAngle = 0;      % deg, clockwise from north
cfg.tracker.azimuth.maxAngle = 360;    % deg
cfg.tracker.azimuth.stowAngle = 0;     % deg, north
cfg.tracker.azimuth.deadband = 0.5;    % deg
cfg.tracker.azimuth.gearRatio = 100;   % preliminary, see G2 sizing
cfg.tracker.azimuth.gearEfficiency = 0.70;
cfg.tracker.azimuth.frictionTorque = 1.0; % N*m at the output

cfg.tracker.elevation.minAngle = 0;    % deg, panel tilt from horizontal
cfg.tracker.elevation.maxAngle = 85;   % deg, avoids the zenith singularity
cfg.tracker.elevation.stowAngle = 0;   % deg, horizontal
cfg.tracker.elevation.deadband = 0.5;  % deg
cfg.tracker.elevation.gearRatio = 150; % preliminary, see G2 sizing
cfg.tracker.elevation.gearEfficiency = 0.70;
cfg.tracker.elevation.frictionTorque = 1.0; % N*m at the output

% Panel properties (preliminary)
cfg.tracker.panel.width = 1.0;         % m
cfg.tracker.panel.height = 1.6;        % m
cfg.tracker.panel.area = cfg.tracker.panel.width * cfg.tracker.panel.height;
cfg.tracker.panel.mass = 12;           % kg
cfg.tracker.panel.centerOfMassOffset = 0.05; % m from the tilt axis
% Inertia estimates include the frame and mounting hardware; they are
% verified in the Gate G2/G3 model.
cfg.tracker.panel.inertiaAboutTiltAxis = 3.5;    % kg*m^2
cfg.tracker.panel.inertiaAboutAzimuthAxis = 8.0; % kg*m^2

% Preliminary sizing inputs
cfg.tracker.designAngularAcceleration = 0.05; % rad/s^2
cfg.tracker.designSlewRate = 2.0;             % deg/s
cfg.tracker.windDisturbanceTorque = 10.0;     % N*m allowance for a balanced panel
% Mean wind torque used in the closed-loop validation model. The design
% allowance above is a worst case; the simulation uses a fraction of it so
% the controllers are not validated against the sizing limit itself.
cfg.tracker.windMeanTorque = 0.2 * cfg.tracker.windDisturbanceTorque; % N*m

% Controller gains (preliminary; tune at Gate G2/G3)
cfg.controller.azimuth.Kp = 1.0;
cfg.controller.azimuth.Ki = 0.1;
cfg.controller.azimuth.Kd = 0.01;
cfg.controller.azimuth.filterCoefficient = 100; % derivative filter, rad/s
cfg.controller.azimuth.outputMin = -24;         % V
cfg.controller.azimuth.outputMax = 24;          % V
% The drive can change the armature voltage within one control step, so the
% rate limit is set to full scale in 10 ms. The earlier value of 48 V/s
% delayed braking by about half a second and was the dominant cause of
% overshoot on a 30 deg step.
cfg.controller.azimuth.rateLimit = 2400;         % V/s
% Gains tuned against the explicit DC-motor plant in
% models/solar_tracker_plant.slx. The reduced-order baseline has a very
% different voltage-to-angle gain, so it keeps the preliminary gains above.
cfg.controller.azimuth.plantKp = 1.2;
cfg.controller.azimuth.plantKi = 0.3;
cfg.controller.azimuth.plantKd = 0.2;
cfg.controller.azimuth.plantFilterCoefficient = 20; % rad/s

cfg.controller.elevation.Kp = 1.0;
cfg.controller.elevation.Ki = 0.1;
cfg.controller.elevation.Kd = 0.01;
cfg.controller.elevation.filterCoefficient = 100;
cfg.controller.elevation.outputMin = -24;       % V
cfg.controller.elevation.outputMax = 24;        % V
cfg.controller.elevation.rateLimit = 2400;      % V/s
cfg.controller.elevation.plantKp = 1.2;
cfg.controller.elevation.plantKi = 0.3;
cfg.controller.elevation.plantKd = 0.2;
cfg.controller.elevation.plantFilterCoefficient = 20; % rad/s

% Actuator parameters (preliminary; replace with the selected motors)
cfg.actuator.azimuth.ratedVoltage = 24;          % V
cfg.actuator.azimuth.armatureResistance = 1.2;   % ohm
cfg.actuator.azimuth.armatureInductance = 0.5e-3;% H
cfg.actuator.azimuth.torqueConstant = 0.05;      % N*m/A
cfg.actuator.azimuth.backEmfConstant = 0.05;     % V*s/rad
cfg.actuator.azimuth.viscousFriction = 1e-4;     % N*m*s/rad, motor side
cfg.actuator.azimuth.staticFriction = 0.01;      % N*m, motor side
cfg.actuator.azimuth.currentLimit = 5;           % A
cfg.actuator.azimuth.gearRatio = cfg.tracker.azimuth.gearRatio;
cfg.actuator.azimuth.gearEfficiency = cfg.tracker.azimuth.gearEfficiency;

cfg.actuator.elevation.ratedVoltage = 24;
cfg.actuator.elevation.armatureResistance = 1.2;
cfg.actuator.elevation.armatureInductance = 0.5e-3;
cfg.actuator.elevation.torqueConstant = 0.05;
cfg.actuator.elevation.backEmfConstant = 0.05;
cfg.actuator.elevation.viscousFriction = 1e-4;
cfg.actuator.elevation.staticFriction = 0.01;
cfg.actuator.elevation.currentLimit = 5;
cfg.actuator.elevation.gearRatio = cfg.tracker.elevation.gearRatio;
cfg.actuator.elevation.gearEfficiency = cfg.tracker.elevation.gearEfficiency;

% Irradiance and energy model (preliminary)
cfg.energy.pvEfficiency = 0.18;          % fraction
cfg.energy.systemLossFactor = 0.85;      % wiring, soiling, mismatch
cfg.energy.clearSkyModel = 'meinel';
cfg.energy.diffuseModel = 'isotropic';
cfg.energy.includeActuatorEnergy = true;
cfg.energy.panelArea = cfg.tracker.panel.area; % m^2

% Weather scenario (preliminary)
cfg.weather.mode = 'clear-sky';
cfg.weather.cloudCover = 0;              % fraction, 0 to 1
cfg.weather.cloudHoldThreshold = 0.7;    % enter CLOUD_HOLD above this value

% Analysis settings
cfg.analysis.year = 2026;
cfg.analysis.timeStepMinutes = 30;
cfg.analysis.axisComparisonFile = fullfile(cfg.paths.metrics, ...
    'axis_comparison.csv');
end
