function results = daily_energy_simulation(options)
% DAILY_ENERGY_SIMULATION  Full-day clear-sky PV energy for a tracker.
%
%   RESULTS = DAILY_ENERGY_SIMULATION(Name, Value) runs a full-day clear-sky
%   simulation at the default site (Malang) and returns the irradiance and
%   PV energy for the selected configuration.
%
%   Options:
%       Date              datetime, default 2026-03-21
%       SiteLatitude      default -7.9666
%       SiteLongitude     default 112.6326
%       TimeZone          default 7
%       SampleTimeMinutes default 1
%       Configuration     "fixed", "azimuth", or "dual-axis"
%       FixedAzimuth      default 0 (north)
%       FixedTilt         default 8
%       PanelArea         default 1.6 m^2
%       PvEfficiency      default 0.18
%       SystemLossFactor  default 0.85
%       Albedo            default 0.20
%
%   RESULTS fields include the time vector, sun angles, panel angles, POA
%   irradiance, PV power, and the daily energy metrics.
%
%   Example:
%       fixed = daily_energy_simulation('Configuration', 'fixed');
%       dual  = daily_energy_simulation('Configuration', 'dual-axis');
%       fprintf('Gain: %.1f%%\n', ...
%           100 * (dual.pvEnergy_kWh / fixed.pvEnergy_kWh - 1));
%
%   See also CLEAR_SKY_IRRADIANCE, PLANE_OF_ARRAY_IRRADIANCE, ENERGY_METRICS.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    options.date (1, 1) datetime = datetime(2026, 3, 21, 0, 0, 0)
    options.siteLatitude (1, 1) double ...
        {mustBeBetween(options.siteLatitude, -90, 90)} = -7.9666
    options.siteLongitude (1, 1) double ...
        {mustBeBetween(options.siteLongitude, -180, 180)} = 112.6326
    options.timeZone (1, 1) double ...
        {mustBeBetween(options.timeZone, -12, 14)} = 7
    options.sampleTimeMinutes (1, 1) double {mustBePositive} = 1
    options.configuration (1, 1) string ...
        {mustBeMember(options.configuration, ...
        ["fixed", "azimuth", "dual-axis"])} = "dual-axis"
    options.fixedAzimuth (1, 1) double ...
        {mustBeBetween(options.fixedAzimuth, 0, 360)} = 0
    options.fixedTilt (1, 1) double ...
        {mustBeBetween(options.fixedTilt, 0, 90)} = 8
    options.panelArea (1, 1) double {mustBePositive} = 1.6
    options.pvEfficiency (1, 1) double ...
        {mustBeBetween(options.pvEfficiency, 0, 1)} = 0.18
    options.systemLossFactor (1, 1) double ...
        {mustBeBetween(options.systemLossFactor, 0, 1)} = 0.85
    options.albedo (1, 1) double ...
        {mustBeBetween(options.albedo, 0, 1)} = 0.20
end

startOfDay = dateshift(options.date, 'start', 'day');
minutesPerDay = 24 * 60;
time = startOfDay + minutes(0:options.sampleTimeMinutes: ...
    (minutesPerDay - options.sampleTimeMinutes));
time = time(:);

sun = solar_position(time, options.siteLatitude, ...
    options.siteLongitude, options.timeZone);
sunAzimuth = [sun.azimuth]';
sunElevation = [sun.elevation]';

irradiance = clear_sky_irradiance(sunElevation);

switch options.configuration
    case "fixed"
        panelAzimuth = repmat(options.fixedAzimuth, size(time));
        panelTilt = repmat(options.fixedTilt, size(time));
    case "azimuth"
        panelAzimuth = sunAzimuth;
        panelTilt = repmat(options.fixedTilt, size(time));
    case "dual-axis"
        target = target_angles(sun);
        panelAzimuth = [target.azimuth]';
        panelTilt = [target.tilt]';
end

poa = plane_of_array_irradiance(sunAzimuth, sunElevation, ...
    panelAzimuth, panelTilt, irradiance, 'Albedo', options.albedo);

pvPower_kW = poa * options.panelArea * options.pvEfficiency ...
    * options.systemLossFactor;
pvPower_kW(sunElevation <= 0) = 0;

metrics = energy_metrics(time, pvPower_kW, zeros(size(time)));

results.configuration = options.configuration;
results.date = startOfDay;
results.time = time;
results.sunAzimuth = sunAzimuth;
results.sunElevation = sunElevation;
results.panelAzimuth = panelAzimuth;
results.panelTilt = panelTilt;
results.poaIrradiance = poa;
results.pvPower_kW = pvPower_kW;
results.poaEnergy_kWh_per_m2 = sum(poa(1:end-1)) ...
    * (options.sampleTimeMinutes / 60);
results.pvEnergy_kWh = metrics.pvEnergy_kWh;
results.peakPvPower_kW = metrics.peakPvPower_kW;
results.meanPoa_kW_per_m2 = mean(poa(sunElevation > 0));
end
