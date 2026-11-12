function [command, state] = tracker_mode_logic(state, sun, measured, options)
% TRACKER_MODE_LOGIC  Supervisory mode and deadband logic for the tracker.
%
%   [COMMAND, STATE] = TRACKER_MODE_LOGIC(STATE, SUN, MEASURED) returns the
%   next mode command for the dual-axis tracker. Pass STATE = [] on the first
%   call and pass the returned STATE on the following calls. SUN is a scalar
%   struct with fields azimuth and elevation in degrees, normally returned by
%   SOLAR_POSITION. MEASURED is a scalar struct with fields azimuth and tilt
%   in degrees, representing the current panel position.
%
%   COMMAND is a struct with the fields:
%       mode            "DAY_TRACK", "DEADBAND_HOLD", "NIGHT_STOW",
%                       "CLOUD_HOLD", or "FAULT_SAFE"
%       targetAzimuth   commanded azimuth, degrees clockwise from north
%       targetTilt      commanded panel tilt, degrees from horizontal
%       azimuthError    wrapped target minus measured azimuth, degrees
%       tiltError       target minus measured tilt, degrees
%       motorsEnabled   true when the controller may drive the motors
%       faultLatched    true while a fault remains latched
%       modeChanged     true when the mode differs from the previous call
%
%   The mode priority is fault, night, cloud, then normal tracking. A fault
%   latches until RESETFAULT is true and FAULT is false. Night stow uses
%   hysteresis: the tracker enters stow at or below SUNELEVATIONSTOW and
%   leaves stow only above SUNELEVATIONRESUME.
%
%   In normal tracking the desired azimuth is the sun azimuth and the desired
%   tilt is 90 - sun elevation, clamped to the mechanical limits. The target
%   is updated only when either axis error exceeds its deadband. Otherwise
%   the previous target is held and the motors are disabled to save energy.
%
%   TRACKER_MODE_LOGIC(..., Name, Value) configures:
%       DeadbandAzimuth        azimuth deadband, default 0.5 deg
%       DeadbandTilt           tilt deadband, default 0.5 deg
%       MinAzimuth             minimum azimuth, default 0 deg
%       MaxAzimuth             maximum azimuth, default 360 deg
%       MinTilt                minimum tilt, default 0 deg
%       MaxTilt                maximum tilt, default 85 deg
%       StowAzimuth            stow azimuth, default 0 deg
%       StowTilt               stow tilt, default 0 deg
%       SunElevationStow       enter stow at or below, default 0 deg
%       SunElevationResume     leave stow above, default 2 deg
%       CloudCover             current cloud cover, default 0
%       CloudCoverThreshold    hold above this cover, default 0.8
%       Fault                  current fault flag, default false
%       ResetFault             clear a latched fault, default false
%
%   Example:
%       sun = struct('azimuth', 120, 'elevation', 45);
%       measured = struct('azimuth', 100, 'tilt', 30);
%       [command, state] = tracker_mode_logic([], sun, measured);
%
%   See also TARGET_ANGLES, SOLAR_POSITION.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    state
    sun struct
    measured struct
    options.deadbandAzimuth (1, 1) double {mustBeNonnegative} = 0.5
    options.deadbandTilt (1, 1) double {mustBeNonnegative} = 0.5
    options.minAzimuth (1, 1) double = 0
    options.maxAzimuth (1, 1) double = 360
    options.minTilt (1, 1) double = 0
    options.maxTilt (1, 1) double = 85
    options.stowAzimuth (1, 1) double = 0
    options.stowTilt (1, 1) double = 0
    options.sunElevationStow (1, 1) double = 0
    options.sunElevationResume (1, 1) double = 2
    options.cloudCover (1, 1) double ...
        {mustBeBetween(options.cloudCover, 0, 1)} = 0
    options.cloudCoverThreshold (1, 1) double ...
        {mustBeBetween(options.cloudCoverThreshold, 0, 1)} = 0.8
    options.fault (1, 1) logical = false
    options.resetFault (1, 1) logical = false
end

if options.sunElevationResume < options.sunElevationStow
    error('tracker_mode_logic:InvalidHysteresis', ...
        'SunElevationResume must be greater than or equal to SunElevationStow.');
end
if options.minAzimuth > options.maxAzimuth
    error('tracker_mode_logic:InvalidAzimuthLimits', ...
        'MinAzimuth must not exceed MaxAzimuth.');
end
if options.minTilt > options.maxTilt
    error('tracker_mode_logic:InvalidTiltLimits', ...
        'MinTilt must not exceed MaxTilt.');
end

firstCall = isempty(state);
if firstCall
    state.mode = "DAY_TRACK";
    state.targetAzimuth = measured.azimuth;
    state.targetTilt = measured.tilt;
    state.faultLatched = false;
end
previousMode = state.mode;

if options.resetFault && ~options.fault
    state.faultLatched = false;
end
if options.fault
    state.faultLatched = true;
end

if state.faultLatched
    mode = "FAULT_SAFE";
else
    if state.mode == "NIGHT_STOW"
        stowNow = sun.elevation <= options.sunElevationResume;
    else
        stowNow = sun.elevation <= options.sunElevationStow;
    end

    if stowNow
        mode = "NIGHT_STOW";
        state.targetAzimuth = options.stowAzimuth;
        state.targetTilt = options.stowTilt;
    elseif options.cloudCover >= options.cloudCoverThreshold
        mode = "CLOUD_HOLD";
    else
        desiredAzimuth = mod(sun.azimuth, 360);
        desiredAzimuth = min(max(desiredAzimuth, options.minAzimuth), ...
            options.maxAzimuth);
        desiredTilt = 90 - sun.elevation;
        desiredTilt = min(max(desiredTilt, options.minTilt), ...
            options.maxTilt);

        azimuthError = localAngleError(desiredAzimuth, measured.azimuth);
        tiltError = desiredTilt - measured.tilt;

        if abs(azimuthError) > options.deadbandAzimuth ...
                || abs(tiltError) > options.deadbandTilt
            mode = "DAY_TRACK";
            state.targetAzimuth = desiredAzimuth;
            state.targetTilt = desiredTilt;
        else
            mode = "DEADBAND_HOLD";
        end
    end
end

azimuthError = localAngleError(state.targetAzimuth, measured.azimuth);
tiltError = state.targetTilt - measured.tilt;

switch mode
    case "DAY_TRACK"
        motorsEnabled = true;
    case "NIGHT_STOW"
        motorsEnabled = abs(azimuthError) > options.deadbandAzimuth ...
            || abs(tiltError) > options.deadbandTilt;
    otherwise
        motorsEnabled = false;
end

command.mode = mode;
command.targetAzimuth = state.targetAzimuth;
command.targetTilt = state.targetTilt;
command.azimuthError = azimuthError;
command.tiltError = tiltError;
command.motorsEnabled = motorsEnabled;
command.faultLatched = state.faultLatched;
command.modeChanged = ~firstCall && mode ~= previousMode;

state.mode = mode;
end

function error = localAngleError(target, measured)
% LOCALANGLEERROR  Shortest signed angular difference in degrees.
error = mod(target - measured + 180, 360) - 180;
end
