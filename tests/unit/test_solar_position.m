classdef test_solar_position < matlab.unittest.TestCase
    % TEST_SOLAR_POSITION  Unit tests for the solar position and geometry code.
    %
    %   The reference case is the NREL Solar Position Algorithm (SPA) example
    %   documented in the SPA report and used by the pvlib test suite:
    %   Golden, Colorado, 2003-10-17 12:30:30 MST (UTC-7), latitude
    %   39.742476 deg, longitude -105.1786 deg.
    %
    %   The expected geometric elevation is 39.872046 deg. The apparent
    %   elevation reported by SPA (39.888378 deg) includes atmospheric
    %   refraction, which this implementation intentionally omits.

    % AI-assisted: test cases drafted with OpenCode/DeepSeek.
    % Reviewed and tested by Jhons on 2026-11-09.

    properties (Constant)
        MalangLatitude = -7.9666;
        MalangLongitude = 112.6326;
        MalangTimeZone = 7;
    end

    methods (Test)
        function testNrelSpaGoldenExample(testCase)
            time = datetime(2003, 10, 17, 12, 30, 30);
            sun = solar_position(time, 39.742476, -105.1786, -7);

            testCase.verifyEqual(sun.azimuth, 194.340241, 'AbsTol', 0.01);
            testCase.verifyEqual(sun.elevation, 39.872046, 'AbsTol', 0.01);
            testCase.verifyEqual(sun.zenith, 50.127954, 'AbsTol', 0.01);
            testCase.verifyEqual(sun.declination, -9.31434, 'AbsTol', 0.01);
            testCase.verifyEqual(sun.hourAngle, 11.10590, 'AbsTol', 0.01);
            testCase.verifyEqual(sun.equationOfTime, 14.64, 'AbsTol', 0.02);
            testCase.verifyTrue(sun.isDay);
        end

        function testTimeZoneEquivalence(testCase)
            localTime = datetime(2026, 3, 21, 12, 0, 0);
            zonedTime = datetime(2026, 3, 21, 12, 0, 0, 'TimeZone', 'Asia/Jakarta');

            localSun = solar_position(localTime, testCase.MalangLatitude, ...
                testCase.MalangLongitude, testCase.MalangTimeZone);
            zonedSun = solar_position(zonedTime, testCase.MalangLatitude, ...
                testCase.MalangLongitude);

            testCase.verifyEqual(zonedSun.azimuth, localSun.azimuth, 'AbsTol', 1e-12);
            testCase.verifyEqual(zonedSun.elevation, localSun.elevation, 'AbsTol', 1e-12);
            testCase.verifyEqual(zonedSun.julianDate, localSun.julianDate, 'AbsTol', 1e-12);
        end

        function testMalangDayAndNight(testCase)
            noon = solar_position(datetime(2026, 3, 21, 12, 0, 0), ...
                testCase.MalangLatitude, testCase.MalangLongitude, testCase.MalangTimeZone);
            midnight = solar_position(datetime(2026, 3, 21, 0, 0, 0), ...
                testCase.MalangLatitude, testCase.MalangLongitude, testCase.MalangTimeZone);

            testCase.verifyTrue(noon.isDay);
            testCase.verifyGreaterThan(noon.elevation, 70);
            testCase.verifyFalse(midnight.isDay);
            testCase.verifyLessThan(midnight.elevation, 0);
        end

        function testMorningSunIsEastAndAfternoonSunIsWest(testCase)
            morning = solar_position(datetime(2026, 3, 21, 9, 0, 0), ...
                testCase.MalangLatitude, testCase.MalangLongitude, testCase.MalangTimeZone);
            afternoon = solar_position(datetime(2026, 3, 21, 15, 0, 0), ...
                testCase.MalangLatitude, testCase.MalangLongitude, testCase.MalangTimeZone);

            testCase.verifyGreaterThan(morning.azimuth, 0);
            testCase.verifyLessThan(morning.azimuth, 180);
            testCase.verifyGreaterThan(afternoon.azimuth, 180);
            testCase.verifyLessThan(afternoon.azimuth, 360);
        end

        function testEquinoxNoonElevation(testCase)
            times = datetime(2026, 3, 21, 10, 0, 0) + minutes(0:5:240);
            sun = solar_position(times, testCase.MalangLatitude, ...
                testCase.MalangLongitude, testCase.MalangTimeZone);
            maximumElevation = max([sun.elevation]);
            expectedElevation = 90 - abs(testCase.MalangLatitude);

            testCase.verifyEqual(maximumElevation, expectedElevation, 'AbsTol', 1.0);
        end

        function testVectorInputReturnsStructArray(testCase)
            times = datetime(2026, 3, 21, 6:2:18, 0, 0);
            sun = solar_position(times, testCase.MalangLatitude, ...
                testCase.MalangLongitude, testCase.MalangTimeZone);

            testCase.verifyNumElements(sun, numel(times));
            testCase.verifyTrue(all([sun.azimuth] >= 0 & [sun.azimuth] < 360));
            testCase.verifyTrue(all(isfinite([sun.elevation])));
        end

        function testInvalidSiteCoordinates(testCase)
            time = datetime(2026, 3, 21, 12, 0, 0);
            testCase.verifyError(@() solar_position(time, 91, 0, 0), ...
                'MATLAB:validators:mustBeBetweenScalarBounds');
            testCase.verifyError(@() solar_position(time, 0, 181, 0), ...
                'MATLAB:validators:mustBeBetweenScalarBounds');
            testCase.verifyError(@() solar_position(time, 0, 0, 15), ...
                'MATLAB:validators:mustBeBetweenScalarBounds');
        end

        function testSolarVectorCardinalDirections(testCase)
            testCase.verifyEqual(solar_vector(0, 0), [0 1 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(solar_vector(90, 0), [1 0 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(solar_vector(180, 0), [0 -1 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(solar_vector(270, 0), [-1 0 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(solar_vector(0, 90), [0 0 1], 'AbsTol', 1e-12);
        end

        function testPanelNormalDefinition(testCase)
            testCase.verifyEqual(panel_normal(0, 0), [0 0 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(panel_normal(0, 90), [0 1 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(panel_normal(90, 90), [1 0 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(panel_normal(180, 45), ...
                [0 -sind(45) cosd(45)], 'AbsTol', 1e-12);
        end

        function testAngleOfIncidence(testCase)
            testCase.verifyEqual(angle_of_incidence(0, 90, 0, 0), 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(angle_of_incidence(90, 0, 90, 90), 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(angle_of_incidence(0, 45, 0, 45), 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(angle_of_incidence(180, 45, 180, 45), 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(angle_of_incidence(90, 0, 0, 0), 90, 'AbsTol', 1e-12);
            testCase.verifyEqual(angle_of_incidence(90, 0, 270, 90), 180, 'AbsTol', 1e-12);
        end
    end
end
