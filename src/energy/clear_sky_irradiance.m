function irradiance = clear_sky_irradiance(sunElevation, options)
% CLEAR_SKY_IRRADIANCE  Clear-sky direct, diffuse, and global irradiance.
%
%   IRR = CLEAR_SKY_IRRADIANCE(SUN_ELEVATION) returns a struct with the
%   fields dni, dhi, and ghi in kW/m^2 for the solar elevation in degrees.
%   The direct normal irradiance uses the Meinel clear-sky model:
%
%       AM  = 1 / sin(elevation)
%       DNI = I0 * tau^(AM^a)
%
%   where I0 = 1.353 kW/m^2, tau = 0.70, and a = 0.678. The diffuse
%   horizontal irradiance is a fixed fraction of DNI, and the global
%   horizontal irradiance is GHI = DNI sin(elevation) + DHI.
%
%   IRR = CLEAR_SKY_IRRADIANCE(..., Name, Value) configures:
%       DiffuseFraction             DHI / DNI, default 0.10
%       ExtraterrestrialIrradiance  I0, default 1.353 kW/m^2
%       AtmosphereTransmission      tau, default 0.70
%       AirMassExponent             a, default 0.678
%
%   The function accepts scalar or vector elevations. Night values
%   (elevation <= 0) are zero. The model is a screening model for clear
%   skies; it does not include clouds, aerosols, or site altitude.
%
%   Example:
%       irr = clear_sky_irradiance(90);
%       irr.dni   % 0.9471 kW/m^2
%
%   See also PLANE_OF_ARRAY_IRRADIANCE, SOLAR_POSITION.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    sunElevation double
    options.diffuseFraction (1, 1) double ...
        {mustBeBetween(options.diffuseFraction, 0, 1)} = 0.10
    options.extraterrestrialIrradiance (1, 1) double ...
        {mustBePositive} = 1.353
    options.atmosphereTransmission (1, 1) double ...
        {mustBeBetween(options.atmosphereTransmission, 0, 1)} = 0.70
    options.airMassExponent (1, 1) double {mustBePositive} = 0.678
end

elevation = sunElevation(:);
dni = zeros(size(elevation));
dhi = zeros(size(elevation));
ghi = zeros(size(elevation));

daytime = elevation > 0;
if any(daytime)
    sineElevation = sind(elevation(daytime));
    airMass = 1 ./ sineElevation;
    dni(daytime) = options.extraterrestrialIrradiance .* ...
        options.atmosphereTransmission .^ ...
        (airMass .^ options.airMassExponent);
    dhi(daytime) = options.diffuseFraction .* dni(daytime);
    ghi(daytime) = dni(daytime) .* sineElevation + dhi(daytime);
end

irradiance.dni = dni;
irradiance.dhi = dhi;
irradiance.ghi = ghi;
end
