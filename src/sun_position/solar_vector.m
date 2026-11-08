function vector = solar_vector(azimuth, elevation)
% SOLAR_VECTOR  Unit vector pointing toward the sun in a local ENU frame.
%
%   V = SOLAR_VECTOR(AZIMUTH, ELEVATION) returns an N-by-3 matrix whose rows
%   are unit vectors in the local east-north-up (ENU) frame. AZIMUTH is
%   measured clockwise from north in degrees, and ELEVATION is measured from
%   the horizontal plane in degrees. Scalars and column vectors are accepted.
%
%   Example:
%       v = solar_vector(90, 0);   % sun due east on the horizon
%       % v = [1 0 0]
%
%   See also PANEL_NORMAL, ANGLE_OF_INCIDENCE.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

azimuth = azimuth(:);
elevation = elevation(:);

% Allow a scalar azimuth or elevation to be combined with a vector.
if isscalar(elevation) && ~isscalar(azimuth)
    elevation = repmat(elevation, size(azimuth));
elseif isscalar(azimuth) && ~isscalar(elevation)
    azimuth = repmat(azimuth, size(elevation));
elseif numel(azimuth) ~= numel(elevation)
    error('solar_vector:SizeMismatch', ...
        'Azimuth and elevation must be scalars or vectors of equal length.');
end

vector = [ ...
    cosd(elevation) .* sind(azimuth), ...
    cosd(elevation) .* cosd(azimuth), ...
    sind(elevation)];
end
