classdef test_target_angles < matlab.unittest.TestCase
    % TEST_TARGET_ANGLES  Unit tests for the tracker target-angle generator.

    % AI-assisted: test cases drafted with OpenCode/DeepSeek.
    % Reviewed and tested by Jhons on 2026-11-09.

    methods (Test)
        function testDaytimeConversion(testCase)
            sun.azimuth = 120;
            sun.elevation = 45;

            target = target_angles(sun);

            testCase.verifyEqual(target.azimuth, 120, 'AbsTol', 1e-12);
            testCase.verifyEqual(target.tilt, 45, 'AbsTol', 1e-12);
            testCase.verifyEqual(target.mode, "DAY_TRACK");
            testCase.verifyTrue(target.isTracking);
        end

        function testNightStow(testCase)
            sun.azimuth = 200;
            sun.elevation = -5;

            target = target_angles(sun);

            testCase.verifyEqual(target.azimuth, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(target.tilt, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(target.mode, "NIGHT_STOW");
            testCase.verifyFalse(target.isTracking);

            % The threshold is strict: the sun exactly on the horizon is
            % treated as night for tracking purposes.
            sun.elevation = 0;
            target = target_angles(sun);
            testCase.verifyEqual(target.mode, "NIGHT_STOW");
        end

        function testMechanicalClamping(testCase)
            sun.azimuth = 10;
            sun.elevation = 85;

            target = target_angles(sun, 'MinAzimuth', 90, 'MaxAzimuth', 270, ...
                'MinTilt', 10, 'MaxTilt', 80);

            testCase.verifyEqual(target.azimuth, 90, 'AbsTol', 1e-12);
            testCase.verifyEqual(target.tilt, 10, 'AbsTol', 1e-12);
        end

        function testCustomStowPosition(testCase)
            sun.azimuth = 200;
            sun.elevation = -10;

            target = target_angles(sun, 'StowAzimuth', 180, 'StowTilt', 85);

            testCase.verifyEqual(target.azimuth, 180, 'AbsTol', 1e-12);
            testCase.verifyEqual(target.tilt, 85, 'AbsTol', 1e-12);
        end

        function testVectorInput(testCase)
            sun(1).azimuth = 90;
            sun(1).elevation = 30;
            sun(2).azimuth = 180;
            sun(2).elevation = 0;
            sun(3).azimuth = 270;
            sun(3).elevation = 10;

            target = target_angles(sun);

            testCase.verifyNumElements(target, 3);
            testCase.verifyEqual([target.tilt], [60, 0, 80], 'AbsTol', 1e-12);
            testCase.verifyEqual([target.isTracking], [true, false, true]);
        end
    end
end
