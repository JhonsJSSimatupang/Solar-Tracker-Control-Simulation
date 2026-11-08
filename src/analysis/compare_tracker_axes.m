function [results, details] = compare_tracker_axes(options)
% COMPARE_TRACKER_AXES  Compare fixed, single-axis, and dual-axis trackers.
%
%   RESULTS = COMPARE_TRACKER_AXES() estimates the annual direct-beam energy
%   collected by four panel configurations at Malang, Indonesia, using the
%   NOAA/Meeus solar position and a clear-sky direct-normal-irradiance proxy.
%
%   RESULTS = COMPARE_TRACKER_AXES(Name, Value) overrides the defaults:
%       SiteLatitude       latitude in degrees, north positive
%       SiteLongitude      longitude in degrees, east positive
%       TimeZone           UTC offset in hours
%       Year               calendar year
%       TimeStepMinutes    sampling interval in minutes
%       SiteName           label used in the figure title
%       WriteFiles         write CSV and PNG output to results/
%
%   [RESULTS, DETAILS] = COMPARE_TRACKER_AXES(...) also returns the tilt
%   sweep curves used to find the optimal fixed tilts.
%
%   The four configurations are:
%       1. Fixed panel at the optimal tilt, facing north.
%       2. Single-axis azimuth tracker at the optimal fixed tilt.
%       3. Horizontal north-south single-axis tracker.
%       4. Ideal dual-axis tracker with the panel normal following the sun.
%
%   The model is a screening tool. It includes only the direct beam and a
%   simple air-mass attenuation; diffuse irradiance, soiling, and actuator
%   energy are added in the full energy model. The absolute values are
%   therefore not the final energy estimate. The relative comparison is used
%   to select the tracker configuration and the preliminary tilt range.
%
%   Example:
%       results = compare_tracker_axes('WriteFiles', true);
%
%   See also SOLAR_POSITION, SOLAR_VECTOR, PANEL_NORMAL.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    options.siteLatitude (1, 1) double {mustBeBetween(options.siteLatitude, -90, 90)} = -7.9666
    options.siteLongitude (1, 1) double {mustBeBetween(options.siteLongitude, -180, 180)} = 112.6326
    options.timeZone (1, 1) double {mustBeBetween(options.timeZone, -12, 14)} = 7
    options.year (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(options.year, 1901), mustBeLessThanOrEqual(options.year, 2099)} = 2026
    options.timeStepMinutes (1, 1) double {mustBePositive} = 30
    options.siteName (1, 1) string = "Malang"
    options.writeFiles (1, 1) logical = false
end

% Build a full-year time vector at the requested sampling interval.
nDays = 365 + (eomday(options.year, 2) == 29);
minutesPerYear = nDays * 24 * 60;
time = datetime(options.year, 1, 1, 0, 0, 0) ...
    + minutes(0:options.timeStepMinutes:(minutesPerYear - options.timeStepMinutes));

% Solar position and unit sun vectors.
sun = solar_position(time, options.siteLatitude, options.siteLongitude, ...
    options.timeZone);
azimuth = [sun.azimuth]';
elevation = [sun.elevation]';
sunVectors = solar_vector(azimuth, elevation);

% Clear-sky direct-normal-irradiance proxy. The 0.01 floor avoids a division
% by zero below the horizon; the night values are set to zero explicitly.
airMass = 1 ./ max(sunVectors(:, 3), 0.01);
dni = 1.353 .* 0.7.^(airMass.^0.678);   % kW/m^2
dni(sunVectors(:, 3) <= 0) = 0;
dtHours = options.timeStepMinutes / 60;

% Sweep the fixed tilt for the fixed and azimuth-tracking cases.
tiltGrid = (0:1:60)';
[fixedTilt, fixedEnergy, fixedCurve] = localOptimizeTilt( ...
    zeros(size(azimuth)), sunVectors, dni, dtHours, tiltGrid);
[azimuthTilt, azimuthEnergy, azimuthCurve] = localOptimizeTilt( ...
    azimuth, sunVectors, dni, dtHours, tiltGrid);

% Horizontal north-south single-axis tracker. The panel normal stays in the
% east-up plane and follows the sun's projection on that plane.
theta = atan2d(sunVectors(:, 1), sunVectors(:, 3));
horizontalNormal = [sind(theta), zeros(size(theta)), cosd(theta)];
horizontalCosine = sum(sunVectors .* horizontalNormal, 2);
horizontalEnergy = sum(max(horizontalCosine, 0) .* dni) * dtHours;

% Ideal dual-axis tracker: the panel normal follows the sun, so the cosine of
% the incidence angle is one whenever the sun is above the horizon.
dualEnergy = sum(dni) * dtHours;

% Assemble the comparison table.
configuration = [
    "Fixed (optimal tilt)"
    "Single-axis azimuth (optimal tilt)"
    "Horizontal N-S single-axis"
    "Dual-axis (ideal)"
    ];
optimalTilt = [fixedTilt; azimuthTilt; NaN; NaN];
energy = [fixedEnergy; azimuthEnergy; horizontalEnergy; dualEnergy];
gain = 100 * (energy / fixedEnergy - 1);

results = table(configuration, optimalTilt, energy, gain, ...
    'VariableNames', {'Configuration', 'OptimalTilt_deg', ...
    'Energy_kWh_per_m2', 'Gain_vs_Fixed_pct'});
results.Properties.Description = sprintf( ...
    'Annual direct-beam proxy, %s %d, %g-minute sampling', ...
    options.siteName, options.year, options.timeStepMinutes);

% Return the curves for documentation and optional plotting.
details.fixedTiltGrid = tiltGrid;
details.fixedEnergyCurve = fixedCurve;
details.azimuthTiltGrid = tiltGrid;
details.azimuthEnergyCurve = azimuthCurve;
details.fixedTilt = fixedTilt;
details.azimuthTilt = azimuthTilt;
details.dniModel = 'Meinel clear-sky direct-beam proxy';
details.energyUnit = 'kWh/m^2/year';

% Optional reproducible outputs.
if options.writeFiles
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    metricsDir = fullfile(root, 'results', 'metrics');
    figuresDir = fullfile(root, 'results', 'figures');
    if ~isfolder(metricsDir)
        mkdir(metricsDir);
    end
    if ~isfolder(figuresDir)
        mkdir(figuresDir);
    end

    writetable(results, fullfile(metricsDir, 'axis_comparison.csv'));

    fig = figure('Visible', 'off');
    bar(results.Energy_kWh_per_m2);
    set(gca, 'XTickLabel', results.Configuration, 'XTickLabelRotation', 20);
    ylabel('Annual direct-beam energy (kWh/m^2)');
    title(sprintf('Tracker axis comparison — %s %d', ...
        options.siteName, options.year));
    grid on;
    exportgraphics(fig, fullfile(figuresDir, 'axis_comparison.png'), ...
        'Resolution', 200);
    close(fig);
end
end

function [bestTilt, bestEnergy, curve] = localOptimizeTilt( ...
    panelAzimuth, sunVectors, dni, dtHours, tiltGrid)
% LOCALOPTIMIZETILT  Sweep a fixed panel tilt and return the maximum energy.

curve = zeros(size(tiltGrid));
for k = 1:numel(tiltGrid)
    normal = panel_normal(panelAzimuth, tiltGrid(k));
    cosine = sum(sunVectors .* normal, 2);
    curve(k) = sum(max(cosine, 0) .* dni) * dtHours;
end
[bestEnergy, index] = max(curve);
bestTilt = tiltGrid(index);
end
