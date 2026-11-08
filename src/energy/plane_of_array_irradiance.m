function poa = plane_of_array_irradiance(sunAzimuth, sunElevation, ...
    panelAzimuth, panelTilt, irradiance, options)
% PLANE_OF_ARRAY_IRRADIANCE  Irradiance on a tilted panel.
%
%   POA = PLANE_OF_ARRAY_IRRADIANCE(SUN_AZ, SUN_EL, PANEL_AZ, PANEL_TILT, IRR)
%   returns the plane-of-array irradiance in kW/m^2 using the isotropic sky
%   model:
%
%       POA = DNI max(cos(AOI), 0)
%           + DHI (1 + cos(tilt)) / 2
%           + GHI albedo (1 - cos(tilt)) / 2
%
%   IRR is a struct returned by CLEAR_SKY_IRRADIANCE with fields dni, dhi,
%   and ghi. SUN_AZ and PANEL_AZ are degrees clockwise from north. SUN_EL
%   and PANEL_TILT are degrees from horizontal. The angle of incidence is
%   computed with ANGLE_OF_INCIDENCE.
%
%   POA = PLANE_OF_ARRAY_IRRADIANCE(..., Name, Value) configures:
%       Albedo  ground reflectance, default 0.20
%
%   Night values are zero when the sun is below the horizon.
%
%   Example:
%       irr = clear_sky_irradiance(30);
%       poa = plane_of_array_irradiance(180, 30, 180, 60, irr);
%
%   See also CLEAR_SKY_IRRADIANCE, ANGLE_OF_INCIDENCE, SOLAR_POSITION.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    sunAzimuth double
    sunElevation double
    panelAzimuth double
    panelTilt double
    irradiance struct
    options.albedo (1, 1) double ...
        {mustBeBetween(options.albedo, 0, 1)} = 0.20
end

[sunAzimuth, sunElevation, panelAzimuth, panelTilt, ...
    dni, dhi, ghi] = localExpandToCommonSize(sunAzimuth, sunElevation, ...
    panelAzimuth, panelTilt, irradiance.dni, irradiance.dhi, irradiance.ghi);

gamma = angle_of_incidence(sunAzimuth, sunElevation, ...
    panelAzimuth, panelTilt);
cosineGamma = max(cosd(gamma), 0);
tilt = panelTilt;

poa = dni .* cosineGamma ...
    + dhi .* (1 + cosd(tilt)) / 2 ...
    + ghi .* options.albedo .* (1 - cosd(tilt)) / 2;

% The sun is below the horizon: no direct or diffuse irradiance is assigned.
poa(sunElevation <= 0) = 0;
end

function varargout = localExpandToCommonSize(varargin)
% LOCALEXPANDTOCOMMONSIZE  Expand scalars and check equal vector lengths.
n = max(cellfun(@numel, varargin));
varargout = cell(1, nargout);
for k = 1:nargout
    x = varargin{k}(:);
    if isscalar(x)
        x = repmat(x, n, 1);
    elseif numel(x) ~= n
        error('plane_of_array_irradiance:SizeMismatch', ...
            'Inputs must be scalars or vectors of equal length.');
    end
    varargout{k} = x;
end
end
