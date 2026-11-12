function [power, details] = tracker_actuator_energy(time, azimuth, tilt, params)
% TRACKER_ACTUATOR_ENERGY  Quasi-static DC-motor power for a tracker day.
%
%   POWER = TRACKER_ACTUATOR_ENERGY(TIME, AZIMUTH, TILT, PARAMS) returns the
%   total electrical power drawn by the two axis motors, in W, at each sample.
%
%   TIME is a datetime vector, AZIMUTH and TILT are the commanded panel angles
%   in degrees, and PARAMS carries the mechanical and electrical parameters of
%   both axes. The returned vector has the same length as TIME; the last value
%   is repeated because the final sample has no following interval.
%
%   The estimate is quasi-static: the angle difference between two samples
%   gives the load speed, and the motor torque follows from a torque balance at
%   that speed. Acceleration torque is not included, because at the daily
%   sample rates used here (1 to 5 minutes) the angular acceleration term is
%   several orders of magnitude below friction and gravity.
%
%   Torque balance at the load, for each axis:
%
%     moving    T_motor = (T_dist + T_friction*sign(w)) / (eta*N)
%     holding   T_motor = sign(T_dist)*max(0, |T_dist| - T_friction) / (eta*N)
%
%   Holding uses the static friction as a brake before the motor has to supply
%   anything. This is the conservative case for a non-self-locking worm gear:
%   the motor holds the panel against gravity and wind all night, so the
%   holding loss appears in the daily energy.
%
%   Armature current is I = |T_motor|/Kt, clamped to the driver limit. The
%   applied voltage is Ke*|w_motor| + Ra*I, clamped to the bus. Power is V*I.
%   Braking energy is dissipated, never recovered; that is stated rather than
%   modelled, because the drive has no regeneration path.
%
%   PARAMS fields, one struct per axis:
%       gearRatio, gearEfficiency, staticFriction, torqueConstant,
%       backEmfConstant, armatureResistance, ratedVoltage, currentLimit
%   plus:
%       azimuth.disturbanceTorque      constant wind torque, N*m
%       elevation.gravityTorqueAmplitude   m*g*L, N*m
%
%   DETAILS returns the per-axis torque, current, voltage, and power vectors.
%
%   See also DAILY_ENERGY_SIMULATION, COMPARE_DAILY_ENERGY, ENERGY_METRICS.

% AI-assisted: model structure drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-11.

arguments
    time (:, 1) datetime
    azimuth (:, 1) double
    tilt (:, 1) double
    params (1, 1) struct
end

n = numel(time);
if numel(azimuth) ~= n || numel(tilt) ~= n
    error('tracker_actuator_energy:SizeMismatch', ...
        'Time, azimuth, and tilt must have the same length.');
end
if n < 2
    power = zeros(n, 1);
    details.azimuth = local_empty_details();
    details.elevation = local_empty_details();
    return
end

tSeconds = seconds(time - time(1));
dt = diff(tSeconds);
if any(dt <= 0)
    error('tracker_actuator_energy:NonIncreasingTime', ...
        'The time vector must be strictly increasing.');
end

% Azimuth is circular: work in the shortest signed angle so a 359 -> 1 deg
% step is a 2 deg move, not a 358 deg sweep.
azimuthStep = mod(diff(azimuth) + 180, 360) - 180;
omegaAzimuth = deg2rad(azimuthStep) ./ dt;
omegaTilt = deg2rad(diff(tilt)) ./ dt;

gravity = params.elevation.gravityTorqueAmplitude ...
    .* cosd(tilt(1:end - 1));

[powerAzimuth, detailsAzimuth] = local_axis_power( ...
    params.azimuth, omegaAzimuth, ...
    repmat(params.azimuth.disturbanceTorque, size(omegaAzimuth)));
[powerTilt, detailsTilt] = local_axis_power( ...
    params.elevation, omegaTilt, gravity);

power = [powerAzimuth + powerTilt; ...
    powerAzimuth(end) + powerTilt(end)];

details.azimuth = detailsAzimuth;
details.elevation = detailsTilt;
end

% -------------------------------------------------------------------------

function [power, details] = local_axis_power(a, omega, disturbance)
% One axis: torque balance, then the electrical operating point.
moving = abs(omega) > 1e-9;
disturbance = disturbance(:);
omega = omega(:);

torqueLoad = zeros(size(omega));
torqueLoad(moving) = disturbance(moving) ...
    + a.staticFriction .* sign(omega(moving));
torqueLoad(~moving) = sign(disturbance(~moving)) ...
    .* max(0, abs(disturbance(~moving)) - a.staticFriction);

% Load torque is reflected to the motor through the gear.
torqueMotor = torqueLoad / (a.gearEfficiency * a.gearRatio);

current = abs(torqueMotor) / a.torqueConstant;
current = min(max(current, 0), a.currentLimit);

omegaMotor = omega * a.gearRatio;
voltage = abs(a.backEmfConstant * omegaMotor) ...
    + a.armatureResistance * current;
voltage = min(voltage, a.ratedVoltage);

power = voltage .* current;

details.torque_Nm = torqueMotor;
details.current_A = current;
details.voltage_V = voltage;
details.power_W = power;
end

function details = local_empty_details()
details.torque_Nm = zeros(0, 1);
details.current_A = zeros(0, 1);
details.voltage_V = zeros(0, 1);
details.power_W = zeros(0, 1);
end
