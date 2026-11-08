function sizing = design_sizing(cfg, options)
% DESIGN_SIZING  Preliminary torque, current, and speed sizing for both axes.
%
%   SIZING = DESIGN_SIZING(CFG) uses the parameter structure returned by
%   PROJECT_CONFIG. It computes the inertia torque, gravity torque, friction,
%   wind disturbance, required output torque, required motor torque, required
%   current, and speed margin for the azimuth and elevation axes.
%
%   SIZING = DESIGN_SIZING(CFG, 'Verbose', false) suppresses the printed
%   summary. The returned structure is always available.
%
%   The calculation is a static, worst-case sizing check. It does not replace
%   the dynamic simulation. It selects the preliminary gear ratios and checks
%   that the motors can meet the requirement at the current limit.
%
%   See also PROJECT_CONFIG, COMPARE_TRACKER_AXES.

arguments
    cfg struct
    options.verbose (1, 1) logical = true
end

g = 9.81;
panel = cfg.tracker.panel;

% Geometric inertia estimates for a thin rectangular plate.
inertiaTiltGeometric = panel.mass * panel.height^2 / 12;
inertiaAzimuthGeometric = panel.mass * ...
    (panel.width^2 + panel.height^2) / 12;

% Worst-case gravity torque on the elevation axis. The center-of-mass offset
% is along the panel height; the torque is maximum when the panel is
% horizontal and decreases as the panel approaches vertical.
tiltAngles = [cfg.tracker.elevation.minAngle, ...
    cfg.tracker.elevation.maxAngle];
gravityTorque = panel.mass * g * panel.centerOfMassOffset ...
    * max(cosd(tiltAngles));

% Azimuth axis: gravity acts parallel to the vertical axis, so it produces no
% torque about the azimuth axis. The term is kept explicit for clarity.
azimuthGravityTorque = 0;

% Azimuth axis sizing.
sizing.azimuth = localAxisSizing( ...
    cfg.tracker.panel.inertiaAboutAzimuthAxis, ...
    cfg.tracker.designAngularAcceleration, ...
    azimuthGravityTorque, ...
    cfg.tracker.azimuth.frictionTorque, ...
    cfg.tracker.windDisturbanceTorque, ...
    cfg.actuator.azimuth, ...
    cfg.tracker.designSlewRate);

% Elevation axis sizing.
sizing.elevation = localAxisSizing( ...
    cfg.tracker.panel.inertiaAboutTiltAxis, ...
    cfg.tracker.designAngularAcceleration, ...
    gravityTorque, ...
    cfg.tracker.elevation.frictionTorque, ...
    cfg.tracker.windDisturbanceTorque, ...
    cfg.actuator.elevation, ...
    cfg.tracker.designSlewRate);

% Panel and assumption data for the design note.
sizing.panel.inertiaTiltGeometric = inertiaTiltGeometric;
sizing.panel.inertiaAzimuthGeometric = inertiaAzimuthGeometric;
sizing.panel.inertiaTiltUsed = panel.inertiaAboutTiltAxis;
sizing.panel.inertiaAzimuthUsed = panel.inertiaAboutAzimuthAxis;
sizing.assumptions.gravity = g;
sizing.assumptions.gravityTorque = gravityTorque;
sizing.assumptions.angularAcceleration = cfg.tracker.designAngularAcceleration;
sizing.assumptions.slewRate = cfg.tracker.designSlewRate;
sizing.assumptions.windTorque = cfg.tracker.windDisturbanceTorque;
sizing.assumptions.note = ['Static worst-case sizing; dynamic effects and ' ...
    'gear backlash are verified in the Simscape model.'];

if options.verbose
    localPrintSummary(cfg, sizing);
end
end

function axis = localAxisSizing(inertia, acceleration, gravityTorque, ...
    frictionTorque, windTorque, actuator, slewRateDegPerSec)
% LOCALAXISSIZING  Compute the torque, current, and speed margins for an axis.

inertiaTorque = inertia * acceleration;
outputTorque = inertiaTorque + gravityTorque + frictionTorque + windTorque;

motorTorque = outputTorque / (actuator.gearRatio * actuator.gearEfficiency);
current = motorTorque / actuator.torqueConstant;

stallTorque = actuator.torqueConstant * actuator.currentLimit;
maxOutputTorque = stallTorque * actuator.gearRatio ...
    * actuator.gearEfficiency;
torqueMargin = maxOutputTorque / outputTorque;

outputSpeed = deg2rad(slewRateDegPerSec); % rad/s
motorSpeed = outputSpeed * actuator.gearRatio;
noLoadSpeed = actuator.ratedVoltage / actuator.backEmfConstant;
speedMargin = noLoadSpeed / motorSpeed;

voltageRequired = current * actuator.armatureResistance ...
    + actuator.backEmfConstant * motorSpeed;
voltageMargin = actuator.ratedVoltage - voltageRequired;

axis.inertia = inertia;
axis.acceleration = acceleration;
axis.inertiaTorque = inertiaTorque;
axis.gravityTorque = gravityTorque;
axis.frictionTorque = frictionTorque;
axis.windTorque = windTorque;
axis.outputTorque = outputTorque;
axis.gearRatio = actuator.gearRatio;
axis.gearEfficiency = actuator.gearEfficiency;
axis.motorTorque = motorTorque;
axis.current = current;
axis.currentLimit = actuator.currentLimit;
axis.currentMargin = actuator.currentLimit - current;
axis.stallTorque = stallTorque;
axis.maxOutputTorque = maxOutputTorque;
axis.torqueMargin = torqueMargin;
axis.outputSpeed = outputSpeed;
axis.motorSpeed = motorSpeed;
axis.noLoadSpeed = noLoadSpeed;
axis.speedMargin = speedMargin;
axis.voltageRequired = voltageRequired;
axis.ratedVoltage = actuator.ratedVoltage;
axis.voltageMargin = voltageMargin;
end

function localPrintSummary(cfg, sizing)
% LOCALPRINTSUMMARY  Print the preliminary sizing table.

fprintf('\nPreliminary actuator sizing — %s\n', cfg.tracker.type);
fprintf('%-10s %8s %8s %8s %8s %8s %9s %8s %8s %8s\n', ...
    'Axis', 'I', 'tauIn', 'tauG', 'tauF', 'tauW', 'tauOut', ...
    'Ireq', 'Ilim', 'Vreq');
localPrintAxis('azimuth', sizing.azimuth);
localPrintAxis('elevation', sizing.elevation);

fprintf('\nMargins (must be greater than 1):\n');
fprintf('  Azimuth   torque %.2f, speed %.2f, current %.2f A, voltage %.2f V\n', ...
    sizing.azimuth.torqueMargin, sizing.azimuth.speedMargin, ...
    sizing.azimuth.currentMargin, sizing.azimuth.voltageMargin);
fprintf('  Elevation torque %.2f, speed %.2f, current %.2f A, voltage %.2f V\n', ...
    sizing.elevation.torqueMargin, sizing.elevation.speedMargin, ...
    sizing.elevation.currentMargin, sizing.elevation.voltageMargin);
fprintf('  Gravity torque at the worst tilt: %.2f N*m\n', ...
    sizing.assumptions.gravityTorque);
fprintf('  Panel inertia (used): tilt %.2f kg*m^2, azimuth %.2f kg*m^2\n', ...
    sizing.panel.inertiaTiltUsed, sizing.panel.inertiaAzimuthUsed);
end

function localPrintAxis(name, axis)
fprintf('%-10s %8.2f %8.3f %8.3f %8.3f %8.3f %9.3f %8.2f %8.2f %8.2f\n', ...
    name, axis.inertia, axis.inertiaTorque, axis.gravityTorque, ...
    axis.frictionTorque, axis.windTorque, axis.outputTorque, ...
    axis.current, axis.currentLimit, axis.voltageRequired);
end
