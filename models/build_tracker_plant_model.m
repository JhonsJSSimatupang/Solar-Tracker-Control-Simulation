function modelPath = build_tracker_plant_model()
% BUILD_TRACKER_PLANT_MODEL  Build the tracker model with explicit axis plants.
%
%   BUILDMODEL = BUILD_TRACKER_PLANT_MODEL() creates
%   models/solar_tracker_plant.slx. The model has the same top-level
%   interface as the baseline model in models/solar_tracker.slx, but each
%   axis is closed around the explicit DC-motor and gear plant produced by
%   BUILD_AXIS_PLANT instead of a gain and an integrator.
%
%   Differences from the baseline model:
%
%     * The controller is a full PID with a filtered derivative on the
%       measured angle, an integrator clamped to the voltage limit, and the
%       configured voltage rate limit.
%     * The plant includes armature resistance and inductance, back-EMF,
%       torque constant, gear ratio and efficiency, viscous and Coulomb
%       friction, and the armature current ceiling.
%     * The elevation axis carries a gravity disturbance torque that depends
%       on the panel tilt. The azimuth axis carries a constant wind torque.
%     * The model uses the configured control sample time and the Simscape
%       networks run with their own local solver at the same rate.
%
%   The model is a validation model, not the full-day production model. A
%   fixed control step of 10 ms over 24 h is not affordable, so the daily
%   energy and tracking study stays on the reduced-order baseline model.
%   This model is used for control and actuator validation over short
%   horizons.
%
%   See also BUILD_AXIS_PLANT, VERIFY_AXIS_PLANT, VALIDATE_TRACKER_PLANT,
%   BUILD_SOLAR_TRACKER_MODEL.

% AI-assisted: model structure drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-11.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(projectRoot, 'src')));
run(fullfile(projectRoot, 'src', 'initialization', 'setup_project.m'));

modelName = 'solar_tracker_plant';
modelPath = fullfile(projectRoot, 'models', [modelName '.slx']);

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if isfile(modelPath)
    delete(modelPath);
end

new_system(modelName);
open_system(modelName);

% The target inputs are replaced by validate_tracker_plant before each run.
% A two-sample default keeps From Workspace from extrapolating.
defaultTime = [0; cfg.simulation.durationHours * 3600];
modelWorkspace = get_param(modelName, 'ModelWorkspace');
assignin(modelWorkspace, 'targetAzimuthInput', timeseries([0; 0], defaultTime));
assignin(modelWorkspace, 'targetTiltInput', timeseries([0; 0], defaultTime));

set_param(modelName, ...
    'Solver', cfg.simulation.solver, ...
    'FixedStep', num2str(cfg.simulation.controllerSampleTime), ...
    'StopTime', '60');

add_from_workspace(modelName, 'TargetAzimuth', 'targetAzimuthInput', [30 55 140 85]);
add_from_workspace(modelName, 'TargetTilt', 'targetTiltInput', [30 275 140 305]);

add_axis(modelName, 'Azimuth', 110, cfg, ...
    cfg.tracker.panel.inertiaAboutAzimuthAxis);

add_axis(modelName, 'Tilt', 330, cfg, ...
    cfg.tracker.panel.inertiaAboutTiltAxis);

% Gravity torque: the lever arm is the centre-of-mass offset projected on
% the horizontal, so T = m*g*L*cos(tilt). Positive tilt lifts the panel.
gravityLever = cfg.tracker.panel.mass * 9.81 * ...
    cfg.tracker.panel.centerOfMassOffset;
add_block('simulink/Math Operations/Gain', [modelName '/GravityScale'], ...
    'Gain', num2str(gravityLever, '%.10g'), ...
    'Position', [560 470 610 500]);
add_block('simulink/Math Operations/Trigonometric Function', ...
    [modelName '/CosTilt'], 'Function', 'cos', ...
    'Position', [490 470 530 500]);
add_block('simulink/Math Operations/Gain', [modelName '/Deg2Rad'], ...
    'Gain', 'pi/180', 'Position', [420 470 450 500]);

add_block('simulink/Sources/Constant', [modelName '/WindTorque'], ...
    'Value', num2str(cfg.tracker.windMeanTorque, '%.10g'), ...
    'Position', [420 120 460 140]);

add_line(modelName, 'TargetAzimuth/1', 'AzimuthErrorSum/1', 'autorouting', 'on');
add_line(modelName, 'TargetTilt/1', 'TiltErrorSum/1', 'autorouting', 'on');

add_block('simulink/Sinks/Out1', [modelName '/AzimuthOutput'], ...
    'Position', [1080 110 1110 130]);
add_block('simulink/Sinks/Out1', [modelName '/TiltOutput'], ...
    'Position', [1080 330 1110 350]);
add_block('simulink/Sinks/Out1', [modelName '/AzimuthError'], ...
    'Position', [1080 170 1110 190]);
add_block('simulink/Sinks/Out1', [modelName '/TiltError'], ...
    'Position', [1080 390 1110 410]);
add_block('simulink/Sinks/Out1', [modelName '/AzimuthCurrent'], ...
    'Position', [1080 210 1110 230]);
add_block('simulink/Sinks/Out1', [modelName '/TiltCurrent'], ...
    'Position', [1080 430 1110 450]);
add_block('simulink/Sinks/Out1', [modelName '/AzimuthVoltage'], ...
    'Position', [1080 250 1110 270]);
add_block('simulink/Sinks/Out1', [modelName '/TiltVoltage'], ...
    'Position', [1080 470 1110 490]);

% A one-step memory in each feedback path breaks the algebraic loop between
% the controller output and the Simscape plant output. The plant has direct
% feedthrough (the applied voltage immediately changes the current, and the
% current immediately changes the torque), so without the delay the loop
% cannot be solved. At a 10 ms step the delay is negligible for a tracker.
add_block('simulink/Discrete/Memory', [modelName '/AzimuthMeas'], ...
    'InitialCondition', '0', 'Position', [660 150 700 180]);
add_block('simulink/Discrete/Memory', [modelName '/TiltMeas'], ...
    'InitialCondition', '0', 'Position', [660 370 700 400]);

add_line(modelName, 'TiltMeas/1', 'Deg2Rad/1', 'autorouting', 'on');
add_line(modelName, 'Deg2Rad/1', 'CosTilt/1', 'autorouting', 'on');
add_line(modelName, 'CosTilt/1', 'GravityScale/1', 'autorouting', 'on');

wire_axis(modelName, 'AzimuthErrorSum', 'AzimuthController', ...
    'AzimuthPlant', 'AzimuthMeas', 'AzimuthOutput', 'AzimuthError');
wire_axis(modelName, 'TiltErrorSum', 'TiltController', ...
    'TiltPlant', 'TiltMeas', 'TiltOutput', 'TiltError');
add_line(modelName, 'AzimuthMeas/1', 'AzimuthErrorSum/2', 'autorouting', 'on');
add_line(modelName, 'TiltMeas/1', 'TiltErrorSum/2', 'autorouting', 'on');
add_line(modelName, 'TiltMeas/1', 'TiltController/2', 'autorouting', 'on');
add_line(modelName, 'AzimuthMeas/1', 'AzimuthController/2', 'autorouting', 'on');

add_line(modelName, 'AzimuthPlant/3', 'AzimuthCurrent/1', 'autorouting', 'on');
add_line(modelName, 'TiltPlant/3', 'TiltCurrent/1', 'autorouting', 'on');
add_line(modelName, 'AzimuthPlant/4', 'AzimuthVoltage/1', 'autorouting', 'on');
add_line(modelName, 'TiltPlant/4', 'TiltVoltage/1', 'autorouting', 'on');

add_line(modelName, 'WindTorque/1', 'AzimuthPlant/2', 'autorouting', 'on');
add_line(modelName, 'GravityScale/1', 'TiltPlant/2', 'autorouting', 'on');

configure_local_solver(modelName, 'AzimuthPlant', ...
    cfg.simulation.controllerSampleTime);
configure_local_solver(modelName, 'TiltPlant', ...
    cfg.simulation.controllerSampleTime);

set_param(modelName, 'SaveOutput', 'on', 'OutputSaveName', 'yout', ...
    'SaveFormat', 'Dataset');

save_system(modelName, modelPath);
% Close the model after saving, so it cannot block a later close_system call
% in the same session with a "model has been changed" warning.
close_system(modelName, 0);
fprintf('Created plant model: %s\n', modelPath);
end

% -------------------------------------------------------------------------

function add_from_workspace(modelName, blockName, variableName, position)
add_block('simulink/Sources/From Workspace', [modelName '/' blockName], ...
    'VariableName', variableName, ...
    'Interpolate', 'on', ...
    'Position', position);
end

function add_axis(modelName, axisName, y, cfg, inertia)
fieldName = lower(axisName);
if strcmp(fieldName, 'tilt')
    fieldName = 'elevation';
end
controller = cfg.controller.(fieldName);
tracker = cfg.tracker.(fieldName);
actuator = cfg.actuator.(fieldName);

% The gains tuned against the explicit plant are separate from the
% preliminary gains used by the reduced-order model: the two plants have
% very different voltage-to-angle gains, so one set cannot serve both.
c.Kp = controller.plantKp;
c.Ki = controller.plantKi;
c.Kd = controller.plantKd;
c.filterCoefficient = controller.plantFilterCoefficient;
c.outputMin = controller.outputMin;
c.outputMax = controller.outputMax;
c.rateLimit = controller.rateLimit;

add_block('simulink/Math Operations/Sum', [modelName '/' axisName 'ErrorSum'], ...
    'Inputs', '+-', 'Position', [100 y 130 y + 30]);

add_pid_controller(modelName, [axisName 'Controller'], c, y);

p.Jload = inertia;
p.Jmotor = 1e-5;
p.N = tracker.gearRatio;
p.eta = tracker.gearEfficiency;
p.B = actuator.viscousFriction;
p.Tc = actuator.staticFriction;
p.Ra = actuator.armatureResistance;
p.La = actuator.armatureInductance;
p.Kt = actuator.torqueConstant;
p.Ke = actuator.backEmfConstant;
p.Vbus = actuator.ratedVoltage;
p.currentLimit = actuator.currentLimit;
p.Ts = cfg.simulation.controllerSampleTime;

build_axis_plant(modelName, [axisName 'Plant'], p);

% The axes are drawn at different vertical positions; move the plant and
% the controller into place so the diagram stays readable.
set_param([modelName '/' axisName 'Plant'], ...
    'Position', [680 y - 40 1040 y + 60]);
set_param([modelName '/' axisName 'Controller'], ...
    'Position', [220 y - 20 390 y + 50]);
end

function add_pid_controller(modelName, name, c, y)
path = [modelName '/' name];
s = @(x) num2str(x, '%.10g');

add_block('built-in/Subsystem', path, ...
    'Position', [220 y - 20 390 y + 50]);
add_block('simulink/Sources/In1', [path '/Error'], ...
    'Position', [20 30 50 44]);
add_block('simulink/Sources/In1', [path '/Measurement'], ...
    'Position', [20 100 50 114]);
add_block('simulink/Sinks/Out1', [path '/Command'], ...
    'Position', [780 30 810 44]);

add_block('simulink/Math Operations/Gain', [path '/Kp'], ...
    'Gain', s(c.Kp), 'Position', [110 20 170 50]);
add_block('simulink/Math Operations/Gain', [path '/Ki'], ...
    'Gain', s(c.Ki), 'Position', [110 90 170 120]);
add_block('simulink/Continuous/Integrator Limited', [path '/Integral'], ...
    'InitialCondition', '0', ...
    'LowerSaturationLimit', s(c.outputMin / c.Ki), ...
    'UpperSaturationLimit', s(c.outputMax / c.Ki), ...
    'Position', [210 90 240 120]);

% Filtered derivative on the measurement. The block realises
% Kd*wf*s/(s + wf), which is Kd times a derivative with a first-order filter
% at wf. Writing the numerator as Kd*wf keeps the effective derivative gain
% equal to Kd; a numerator of Kd alone would attenuate it by wf.
add_block('simulink/Continuous/Transfer Fcn', [path '/Kd'], ...
    'Numerator', mat2str([c.Kd * c.filterCoefficient 0], 10), ...
    'Denominator', mat2str([1 c.filterCoefficient], 10), ...
    'Position', [110 160 190 200]);

add_block('simulink/Math Operations/Sum', [path '/PID_Sum'], ...
    'Inputs', '++-', 'Position', [300 40 330 110]);
add_block('simulink/Discontinuities/Rate Limiter', [path '/RateLimit'], ...
    'RisingSlewLimit', s(c.rateLimit), ...
    'FallingSlewLimit', s(-c.rateLimit), ...
    'Position', [380 40 420 110]);
add_block('simulink/Discontinuities/Saturation', [path '/VoltageLimit'], ...
    'UpperLimit', s(c.outputMax), ...
    'LowerLimit', s(c.outputMin), ...
    'Position', [460 50 500 100]);

add_line(path, 'Error/1', 'Kp/1', 'autorouting', 'on');
add_line(path, 'Error/1', 'Ki/1', 'autorouting', 'on');
add_line(path, 'Ki/1', 'Integral/1', 'autorouting', 'on');
add_line(path, 'Measurement/1', 'Kd/1', 'autorouting', 'on');
add_line(path, 'Kp/1', 'PID_Sum/1', 'autorouting', 'on');
add_line(path, 'Integral/1', 'PID_Sum/2', 'autorouting', 'on');
add_line(path, 'Kd/1', 'PID_Sum/3', 'autorouting', 'on');
add_line(path, 'PID_Sum/1', 'RateLimit/1', 'autorouting', 'on');
add_line(path, 'RateLimit/1', 'VoltageLimit/1', 'autorouting', 'on');
add_line(path, 'VoltageLimit/1', 'Command/1', 'autorouting', 'on');
end

function wire_axis(modelName, errorSum, controllerName, plantName, measName, ...
        outputName, errorOutputName)
add_line(modelName, [errorSum '/1'], [controllerName '/1'], 'autorouting', 'on');
add_line(modelName, [controllerName '/1'], [plantName '/1'], 'autorouting', 'on');
add_line(modelName, [plantName '/1'], [measName '/1'], 'autorouting', 'on');
add_line(modelName, [measName '/1'], [outputName '/1'], 'autorouting', 'on');
add_line(modelName, [errorSum '/1'], [errorOutputName '/1'], 'autorouting', 'on');
end

function configure_local_solver(modelName, plantName, sampleTime)
% Each axis contains two independent Simscape networks: the electrical loop
% and the mechanical loop. Both need a solver configuration, and both must
% use a local solver because the parent model is fixed-step.
solvers = {'SolverE', 'SolverM'};
for k = 1:numel(solvers)
    block = [modelName '/' plantName '/' solvers{k}];
    set_param(block, ...
        'UseLocalSolver', 'on', ...
        'LocalSolverChoice', 'NE_BACKWARD_EULER_ADVANCER', ...
        'LocalSolverSampleTime', num2str(sampleTime));
end
end
