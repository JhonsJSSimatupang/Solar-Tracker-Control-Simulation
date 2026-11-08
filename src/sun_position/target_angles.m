function target = target_angles(sun, options)
% TARGET_ANGLES  Convert solar position to panel azimuth and tilt targets.
%
%   TARGET = TARGET_ANGLES(SUN) accepts a scalar struct or struct array
%   returned by SOLAR_POSITION and returns a struct array with the fields:
%       azimuth      target panel azimuth, degrees clockwise from north
%       tilt         target panel tilt, degrees from horizontal
%       mode         "DAY_TRACK" or "NIGHT_STOW"
%       isTracking   true when the sun is above the tracking threshold
%
%   TARGET = TARGET_ANGLES(SUN, Name, Value) configures the mechanical limits
%   and the night-stow position:
%       MinAzimuth              minimum azimuth, default 0 deg
%       MaxAzimuth              maximum azimuth, default 360 deg
%       MinTilt                 minimum panel tilt, default 0 deg
%       MaxTilt                 maximum panel tilt, default 85 deg
%       StowAzimuth             night-stow azimuth, default 0 deg
%       StowTilt                night-stow tilt, default 0 deg
%       SunElevationThreshold   tracking threshold, default 0 deg
%
%   The panel tilt is the complement of the solar elevation:
%
%       tilt = 90 - elevation
%
%   A horizontal panel (tilt = 0) faces the zenith, and a vertical panel
%   (tilt = 90) faces the horizon. For a dual-axis tracker the panel normal
%   then coincides with the sun vector.
%
%   Example:
%       sun = solar_position(datetime(2026, 3, 21, 9, 0, 0), ...
%           -7.9666, 112.6326, 7);
%       target = target_angles(sun);
%
%   See also SOLAR_POSITION, PANEL_NORMAL, ANGLE_OF_INCIDENCE.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    sun struct
    options.minAzimuth (1, 1) double = 0
    options.maxAzimuth (1, 1) double = 360
    options.minTilt (1, 1) double = 0
    options.maxTilt (1, 1) double = 85
    options.stowAzimuth (1, 1) double = 0
    options.stowTilt (1, 1) double = 0
    options.sunElevationThreshold (1, 1) double = 0
end

n = numel(sun);
azimuth = zeros(n, 1);
tilt = zeros(n, 1);
mode = strings(n, 1);
isTracking = false(n, 1);

for k = 1:n
    if sun(k).elevation > options.sunElevationThreshold
        azimuth(k) = mod(sun(k).azimuth, 360);
        tilt(k) = 90 - sun(k).elevation;

        azimuth(k) = min(max(azimuth(k), options.minAzimuth), ...
            options.maxAzimuth);
        tilt(k) = min(max(tilt(k), options.minTilt), options.maxTilt);

        mode(k) = "DAY_TRACK";
        isTracking(k) = true;
    else
        azimuth(k) = options.stowAzimuth;
        tilt(k) = options.stowTilt;
        mode(k) = "NIGHT_STOW";
        isTracking(k) = false;
    end
end

target = struct( ...
    'azimuth', num2cell(azimuth), ...
    'tilt', num2cell(tilt), ...
    'mode', num2cell(mode), ...
    'isTracking', num2cell(isTracking));
end
