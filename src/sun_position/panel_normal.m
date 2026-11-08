function normal = panel_normal(azimuth, tilt)
% PANEL_NORMAL  Unit normal vector of a tilted panel in a local ENU frame.
%
%   N = PANEL_NORMAL(AZIMUTH, TILT) returns an N-by-3 matrix whose rows are
%   unit normal vectors in the local east-north-up (ENU) frame. AZIMUTH is
%   the direction the panel faces, measured clockwise from north in degrees.
%   TILT is the panel inclination from the horizontal plane in degrees
%   (0 = horizontal, 90 = vertical). Scalars and column vectors are accepted.
%
%   See also SOLAR_VECTOR, ANGLE_OF_INCIDENCE.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

azimuth = azimuth(:);
tilt = tilt(:);

% Allow a scalar azimuth or tilt to be combined with a vector.
if isscalar(tilt) && ~isscalar(azimuth)
    tilt = repmat(tilt, size(azimuth));
elseif isscalar(azimuth) && ~isscalar(tilt)
    azimuth = repmat(azimuth, size(tilt));
elseif numel(azimuth) ~= numel(tilt)
    error('panel_normal:SizeMismatch', ...
        'Azimuth and tilt must be scalars or vectors of equal length.');
end

normal = [ ...
    sind(tilt) .* sind(azimuth), ...
    sind(tilt) .* cosd(azimuth), ...
    cosd(tilt)];
end
