function [results, details] = compare_daily_energy(options)
% COMPARE_DAILY_ENERGY  Compare fixed, azimuth, and dual-axis daily energy.
%
%   RESULTS = COMPARE_DAILY_ENERGY(Name, Value) runs DAILY_ENERGY_SIMULATION
%   for the three configurations with the same irradiance model and returns
%   a table with the daily PV energy and the gain against the fixed case.
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
    'Configuration', 'azimuth', 'FixedTilt', options.azimuthTilt);
dual = daily_energy_simulation(common{:}, ...
    'Configuration', 'dual-axis');

configuration = ["Fixed"; "Single-axis azimuth"; "Dual-axis"];
tilt = [options.fixedTilt; options.azimuthTilt; NaN];
pvEnergy_kWh = [fixed.pvEnergy_kWh; azimuth.pvEnergy_kWh; ...
    dual.pvEnergy_kWh];
gain = 100 * (pvEnergy_kWh / fixed.pvEnergy_kWh - 1);

results = table(configuration, tilt, pvEnergy_kWh, gain, ...
    'VariableNames', {'Configuration', 'Tilt_deg', ...
    'PvEnergy_kWh', 'Gain_vs_Fixed_pct'});
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
