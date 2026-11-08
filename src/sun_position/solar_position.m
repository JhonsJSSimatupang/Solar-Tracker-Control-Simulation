function sun = solar_position(time, latitude, longitude, timeZone)
% SOLAR_POSITION  Solar azimuth and elevation using the NOAA/Meeus algorithm.
%
%   SUN = SOLAR_POSITION(TIME, LAT, LON) returns the apparent solar position
%   for the local civil time in TIME. TIME is a scalar or array of datetime
%   values without a time zone; LAT and LON are the site latitude and
%   longitude in degrees (north and east positive). The local time is
%   interpreted as UTC unless TIMEZONE is specified.
%
%   SUN = SOLAR_POSITION(TIME, LAT, LON, TIMEZONE) uses TIMEZONE, the offset
%   from UTC in hours (for example +7 for Malang). If TIME has a TimeZone
%   property, that time zone is used and TIMEZONE is ignored.
%
%   The output is a struct array with the fields:
%       azimuth         Solar azimuth, degrees clockwise from north [0, 360)
%       elevation       Geometric solar elevation, degrees
%       zenith          Solar zenith angle, degrees
%       declination     Solar declination, degrees
%       hourAngle       Solar hour angle, degrees (-180 to 180)
%       equationOfTime  Equation of time, minutes
%       julianDate      Julian date of the UTC time
%       isDay           True when the geometric elevation is positive
%
%   The algorithm follows the NOAA Solar Calculator equations, which are
%   based on Meeus, Astronomical Algorithms. The elevation is geometric and
%   does not include atmospheric refraction. For dates between 1901 and
%   2099 the expected accuracy is better than 0.02 degrees.
%
%   Example:
%       t = datetime(2026, 3, 21, 12, 0, 0);
%       sun = solar_position(t, -7.9666, 112.6326, 7);
%
%   See also SOLAR_VECTOR, ANGLE_OF_INCIDENCE.

% AI-assisted: initial implementation drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

arguments
    time datetime
    latitude (1, 1) double {mustBeBetween(latitude, -90, 90)}
    longitude (1, 1) double {mustBeBetween(longitude, -180, 180)}
    timeZone (1, 1) double {mustBeBetween(timeZone, -12, 14)} = 0
end

% A datetime with a TimeZone already represents an absolute instant. Keep it
% and convert the display to UTC. Otherwise, treat the input as local civil
% time and subtract the supplied UTC offset.
if ~isempty(time(1).TimeZone)
    utcTime = time;
    utcTime.TimeZone = 'UTC';
else
    utcTime = time - hours(timeZone);
    utcTime.TimeZone = 'UTC';
end

% Julian date and Julian century. posixtime returns seconds since the Unix
% epoch, so no datenum conversion is needed.
julianDate = posixtime(utcTime) / 86400 + 2440587.5;
T = (julianDate - 2451545.0) / 36525.0;

% Geometric mean longitude and mean anomaly of the sun, degrees.
meanLongitude = mod(280.46646 + T .* (36000.76983 + T .* 0.0003032), 360);
meanAnomaly = 357.52911 + T .* (35999.05029 - 0.0001537 .* T);

% Eccentricity of the Earth's orbit.
eccentricity = 0.016708634 - T .* (0.000042037 + 0.0000001267 .* T);

% Equation of the center, true longitude, and apparent longitude.
center = sind(meanAnomaly) .* (1.914602 - T .* (0.004817 + 0.000014 .* T)) ...
    + sind(2 * meanAnomaly) .* (0.019993 - 0.000101 .* T) ...
    + sind(3 * meanAnomaly) * 0.000289;
trueLongitude = meanLongitude + center;
apparentLongitude = trueLongitude - 0.00569 ...
    - 0.00478 .* sind(125.04 - 1934.136 .* T);

% Mean and corrected obliquity of the ecliptic, degrees.
meanObliquity = 23 + (26 + (21.448 - T .* (46.815 + T .* (0.00059 ...
    - T .* 0.001813))) / 60) / 60;
obliquity = meanObliquity + 0.00256 .* cosd(125.04 - 1934.136 .* T);

% Solar declination, degrees.
declination = asind(sind(obliquity) .* sind(apparentLongitude));

% Equation of time, minutes.
y = tand(obliquity / 2).^2;
equationOfTime = 4 .* rad2deg(y .* sind(2 * meanLongitude) ...
    - 2 * eccentricity .* sind(meanAnomaly) ...
    + 4 * eccentricity .* y .* sind(meanAnomaly) .* cosd(2 * meanLongitude) ...
    - 0.5 * y.^2 .* sind(4 * meanLongitude) ...
    - 1.25 * eccentricity.^2 .* sind(2 * meanAnomaly));

% True solar time and hour angle. Using UTC avoids a separate time-zone
% correction: TST = UTC + equation of time + 4 * longitude.
minuteOfDayUTC = hour(utcTime) * 60 + minute(utcTime) + second(utcTime) / 60;
trueSolarTime = mod(minuteOfDayUTC + equationOfTime + 4 * longitude, 1440);
hourAngle = trueSolarTime / 4 - 180;

% Solar elevation and azimuth. The azimuth is measured clockwise from north.
sinElevation = sind(latitude) .* sind(declination) ...
    + cosd(latitude) .* cosd(declination) .* cosd(hourAngle);
sinElevation = min(max(sinElevation, -1), 1);
elevation = asind(sinElevation);
zenith = 90 - elevation;

eastComponent = -cosd(declination) .* sind(hourAngle);
northComponent = sind(declination) .* cosd(latitude) ...
    - cosd(declination) .* sind(latitude) .* cosd(hourAngle);
azimuth = mod(atan2d(eastComponent, northComponent), 360);

% Return a struct array so scalar and vector inputs have the same interface.
sun = struct( ...
    'azimuth', num2cell(azimuth), ...
    'elevation', num2cell(elevation), ...
    'zenith', num2cell(zenith), ...
    'declination', num2cell(declination), ...
    'hourAngle', num2cell(hourAngle), ...
    'equationOfTime', num2cell(equationOfTime), ...
    'julianDate', num2cell(julianDate), ...
    'isDay', num2cell(elevation > 0));
end
