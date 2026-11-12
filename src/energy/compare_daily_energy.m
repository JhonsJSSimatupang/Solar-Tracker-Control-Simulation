function [results, details] = compare_daily_energy(options)
% COMPARE_DAILY_ENERGY  Compare fixed, azimuth, and dual-axis daily energy.
%
%   RESULTS = COMPARE_DAILY_ENERGY(Name, Value) runs DAILY_ENERGY_SIMULATION
%   for the three configurations with the same irradiance model and returns
%   a table with the daily PV energy, the actuator energy, the net energy,
%   and the gain against the fixed case.
%
%   The actuator energy uses the DC-motor and gear parameters from
%   project_config through TRACKER_ACTUATOR_ENERGY, so the net energy is the
%   primary comparison: a tracker that captures more irradiance but spends it
%   on motors is not automatically better.
%
%   [RESULTS, DETAILS] = COMPARE_DAILY_ENERGY(...) also returns the full
%   daily profiles for the three configurations.
%
%   Options:
%       Date              default 2026-03-21
%       SiteLatitude      default -7.9666
%       SiteLongitude     default 112.6326
%       TimeZone          default 7
%       SampleTimeMinutes default 5
%       FixedTilt         default 8 (fixed panel optimum)
%       AzimuthTilt       default 43 (azimuth tracker optimum)
%       PanelArea         default 1.6 m^2
%       PvEfficiency      default 0.18
%       SystemLossFactor  default 0.85
%       Albedo            default 0.20
%       WriteFiles        default false
%
%   See also DAILY_ENERGY_SIMULATION, COMPARE_TRACKER_AXES.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    options.date (1, 1) datetime = datetime(2026, 3, 21, 0, 0, 0)
    options.siteLatitude (1, 1) double = -7.9666
    options.siteLongitude (1, 1) double = 112.6326
    options.timeZone (1, 1) double = 7
    options.sampleTimeMinutes (1, 1) double = 5
    options.fixedTilt (1, 1) double = 8
    options.azimuthTilt (1, 1) double = 43
    options.panelArea (1, 1) double = 1.6
    options.pvEfficiency (1, 1) double = 0.18
    options.systemLossFactor (1, 1) double = 0.85
    options.albedo (1, 1) double = 0.20
    options.writeFiles (1, 1) logical = false
end

common = { ...
    'Date', options.date, ...
    'SiteLatitude', options.siteLatitude, ...
    'SiteLongitude', options.siteLongitude, ...
    'TimeZone', options.timeZone, ...
    'SampleTimeMinutes', options.sampleTimeMinutes, ...
    'PanelArea', options.panelArea, ...
    'PvEfficiency', options.pvEfficiency, ...
    'SystemLossFactor', options.systemLossFactor, ...
    'Albedo', options.albedo};

fixed = daily_energy_simulation(common{:}, ...
    'Configuration', 'fixed', 'FixedAzimuth', 0, ...
    'FixedTilt', options.fixedTilt);
azimuth = daily_energy_simulation(common{:}, ...
    'Configuration', 'azimuth', 'FixedTilt', options.azimuthTilt, ...
    'ActuatorParameters', actuatorParameters('azimuth'));
dual = daily_energy_simulation(common{:}, ...
    'Configuration', 'dual-axis', ...
    'ActuatorParameters', actuatorParameters('dual'));

configuration = ["Fixed"; "Single-axis azimuth"; "Dual-axis"];
tilt = [options.fixedTilt; options.azimuthTilt; NaN];
pvEnergy_kWh = [fixed.pvEnergy_kWh; azimuth.pvEnergy_kWh; ...
    dual.pvEnergy_kWh];
actuatorEnergy_kWh = [fixed.actuatorEnergy_kWh; ...
    azimuth.actuatorEnergy_kWh; dual.actuatorEnergy_kWh];
netEnergy_kWh = pvEnergy_kWh - actuatorEnergy_kWh;
gain = 100 * (pvEnergy_kWh / fixed.pvEnergy_kWh - 1);
netGain = 100 * (netEnergy_kWh / fixed.pvEnergy_kWh - 1);

results = table(configuration, tilt, pvEnergy_kWh, actuatorEnergy_kWh, ...
    netEnergy_kWh, gain, netGain, ...
    'VariableNames', {'Configuration', 'Tilt_deg', 'PvEnergy_kWh', ...
    'ActuatorEnergy_kWh', 'NetEnergy_kWh', 'Gain_vs_Fixed_pct', ...
    'NetGain_vs_Fixed_pct'});
results.Properties.Description = sprintf( ...
    'Daily clear-sky PV energy, %s, %g-minute sampling', ...
    string(options.date), options.sampleTimeMinutes);

details.fixed = fixed;
details.azimuth = azimuth;
details.dual = dual;
details.irradianceModel = 'Meinel clear-sky with isotropic diffuse';
details.pvModel = sprintf('%.0f%% efficiency, %.2f loss factor, %.1f m^2', ...
    100 * options.pvEfficiency, options.systemLossFactor, ...
    options.panelArea);

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
    writetable(results, fullfile(metricsDir, ...
        'daily_energy_comparison.csv'));

    fig = figure('Visible', 'off');
    plot(fixed.time, fixed.pvPower_kW, 'LineWidth', 1.5);
    hold on;
    plot(azimuth.time, azimuth.pvPower_kW, 'LineWidth', 1.5);
    plot(dual.time, dual.pvPower_kW, 'LineWidth', 1.5);
    hold off;
    grid on;
    xlabel('Local time');
    ylabel('PV power (kW)');
    title(sprintf('Daily PV power — %s', ...
        string(options.date, 'yyyy-MM-dd')));
    legend('Fixed 8°', 'Azimuth, tilt 43°', 'Dual-axis', ...
        'Location', 'northwest');
    exportgraphics(fig, fullfile(figuresDir, ...
        'daily_energy_comparison.png'), 'Resolution', 200);
    close(fig);
end
end

% -------------------------------------------------------------------------

function params = actuatorParameters(mode)
% Build the actuator model from the project configuration. The fixed case has
% no motors at all, and the single-axis case has no elevation motor, so the
% gravity amplitude is zeroed rather than the axis removed: a zero disturbance
% and a constant tilt give exactly zero elevation energy.
cfg = project_config();

params.azimuth.gearRatio = cfg.tracker.azimuth.gearRatio;
params.azimuth.gearEfficiency = cfg.tracker.azimuth.gearEfficiency;
params.azimuth.staticFriction = cfg.actuator.azimuth.staticFriction;
params.azimuth.torqueConstant = cfg.actuator.azimuth.torqueConstant;
params.azimuth.backEmfConstant = cfg.actuator.azimuth.backEmfConstant;
params.azimuth.armatureResistance = ...
    cfg.actuator.azimuth.armatureResistance;
params.azimuth.ratedVoltage = cfg.actuator.azimuth.ratedVoltage;
params.azimuth.currentLimit = cfg.actuator.azimuth.currentLimit;
params.azimuth.disturbanceTorque = cfg.tracker.windMeanTorque;

params.elevation.gearRatio = cfg.tracker.elevation.gearRatio;
params.elevation.gearEfficiency = cfg.tracker.elevation.gearEfficiency;
params.elevation.staticFriction = cfg.actuator.elevation.staticFriction;
params.elevation.torqueConstant = cfg.actuator.elevation.torqueConstant;
params.elevation.backEmfConstant = cfg.actuator.elevation.backEmfConstant;
params.elevation.armatureResistance = ...
    cfg.actuator.elevation.armatureResistance;
params.elevation.ratedVoltage = cfg.actuator.elevation.ratedVoltage;
params.elevation.currentLimit = cfg.actuator.elevation.currentLimit;
params.elevation.gravityTorqueAmplitude = cfg.tracker.panel.mass * 9.81 ...
    * cfg.tracker.panel.centerOfMassOffset;

if strcmp(mode, 'azimuth')
    params.elevation.gravityTorqueAmplitude = 0;
    params.azimuth.disturbanceTorque = cfg.tracker.windMeanTorque;
end
end
