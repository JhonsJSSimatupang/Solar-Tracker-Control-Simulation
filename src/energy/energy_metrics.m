function metrics = energy_metrics(time, pvPower, actuatorPower, options)
% ENERGY_METRICS  Integrate PV and actuator power into energy metrics.
%
%   METRICS = ENERGY_METRICS(TIME, PV_POWER, ACTUATOR_POWER) integrates the
%   PV power in kW and the total actuator power in W over time. TIME is a
%   datetime vector or a numeric vector in seconds. Actuator power may be
%   omitted or empty; it then defaults to zero.
%
%   METRICS = ENERGY_METRICS(..., 'ReferenceEnergy_kWh', E) adds the gain
%   against a reference PV energy.
%
%   Returned fields:
%       pvEnergy_kWh            captured PV energy
%       actuatorEnergy_kWh      actuator electrical energy
%       netEnergy_kWh           pvEnergy - actuatorEnergy
%       duration_hours          integration duration
%       peakPvPower_kW          maximum PV power
%       meanPvPower_kW          average PV power over the full duration
%       referenceEnergy_kWh     reference energy, NaN if not supplied
%       gain_vs_reference_pct   gain against the reference, NaN if not supplied
%
%   Example:
%       t = datetime(2026, 3, 21) + hours(0:2);
%       p = [0; 1; 0];
%       metrics = energy_metrics(t, p, 100);
%
%   See also DAILY_ENERGY_SIMULATION, CLEAR_SKY_IRRADIANCE.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    time
    pvPower double
    actuatorPower double = 0
    options.referenceEnergy_kWh (1, 1) double = NaN
end

time = time(:);
pvPower = pvPower(:);

if isempty(actuatorPower)
    actuatorPower = zeros(size(pvPower));
else
    actuatorPower = actuatorPower(:);
end

n = numel(time);
if numel(pvPower) ~= n || numel(actuatorPower) ~= n
    error('energy_metrics:SizeMismatch', ...
        'Time, PV power, and actuator power must have the same length.');
end

if isdatetime(time)
    tSeconds = seconds(time - time(1));
else
    tSeconds = time - time(1);
end

dtSeconds = diff(tSeconds);
if any(dtSeconds < 0)
    error('energy_metrics:NonMonotonicTime', ...
        'The time vector must be nondecreasing.');
end

pvEnergy_kWh = sum(pvPower(1:end-1) .* dtSeconds) / 3600;
actuatorEnergy_kWh = sum(actuatorPower(1:end-1) .* dtSeconds) / 3600 / 1000;

metrics.pvEnergy_kWh = pvEnergy_kWh;
metrics.actuatorEnergy_kWh = actuatorEnergy_kWh;
metrics.netEnergy_kWh = pvEnergy_kWh - actuatorEnergy_kWh;
metrics.duration_hours = tSeconds(end) / 3600;
metrics.peakPvPower_kW = max(pvPower);
metrics.meanPvPower_kW = pvEnergy_kWh / metrics.duration_hours;
metrics.referenceEnergy_kWh = options.referenceEnergy_kWh;
if isnan(options.referenceEnergy_kWh)
    metrics.gain_vs_reference_pct = NaN;
else
    metrics.gain_vs_reference_pct = 100 * ...
        (pvEnergy_kWh / options.referenceEnergy_kWh - 1);
end
end
