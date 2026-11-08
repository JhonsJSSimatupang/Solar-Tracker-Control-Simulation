function gamma = angle_of_incidence(sunAzimuth, sunElevation, panelAzimuth, panelTilt)
% ANGLE_OF_INCIDENCE  Angle between the sun vector and a panel normal.
%
%   GAMMA = ANGLE_OF_INCIDENCE(SUN_AZ, SUN_EL, PANEL_AZ, PANEL_TILT) returns
%   the angle of incidence in degrees. All angles are in degrees. SUN_AZ and
%   PANEL_AZ are measured clockwise from north; SUN_EL and PANEL_TILT are
%   measured from the horizontal plane.
%
%   Scalars and column vectors of equal length are accepted. GAMMA is 0 when
%   the sun is perpendicular to the panel and 90 when the sun is parallel to
%   the panel. Values above 90 mean the panel is facing away from the sun.
%
%   Example:
%       % Horizontal panel, sun at zenith: incidence = 0 degrees.
%       gamma = angle_of_incidence(0, 90, 0, 0);
%
%   See also SOLAR_VECTOR, PANEL_NORMAL.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

sunVector = solar_vector(sunAzimuth, sunElevation);
normalVector = panel_normal(panelAzimuth, panelTilt);

cosineGamma = sum(sunVector .* normalVector, 2);
cosineGamma = min(max(cosineGamma, -1), 1);

gamma = acosd(cosineGamma);
end
