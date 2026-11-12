classdef test_mode_logic < matlab.unittest.TestCase
    % TEST_MODE_LOGIC  Unit tests for the tracker mode and deadband logic.
    %
    %   The tests cover the day-tracking, deadband-hold, night-stow,
    %   cloud-hold, and fault-safe modes, including the night hysteresis and
    %   the wrapped azimuth error.

    % AI-assisted: test cases drafted with OpenCode/DeepSeek.
    % Reviewed and tested by Jhons on 2026-11-09.

    methods (Test)
        function testDayTrack(testCase)
            sun = makeSun(120, 45);
            measured = makeMeasured(100, 30);

            [command, state] = tracker_mode_logic([], sun, measured);

            testCase.verifyEqual(command.mode, "DAY_TRACK");
            testCase.verifyEqual(command.targetAzimuth, 120, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.targetTilt, 45, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.azimuthError, 20, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.tiltError, 15, 'AbsTol', 1e-12);
            testCase.verifyTrue(command.motorsEnabled);
            testCase.verifyFalse(command.faultLatched);
            testCase.verifyFalse(command.modeChanged);
            testCase.verifyEqual(state.mode, "DAY_TRACK");
        end

        function testDeadbandHold(testCase)
            [~, state] = tracker_mode_logic([], makeSun(120, 45), ...
                makeMeasured(100, 30));

            [command, state] = tracker_mode_logic(state, ...
                makeSun(120.3, 45.1), makeMeasured(120.1, 45.0));

            testCase.verifyEqual(command.mode, "DEADBAND_HOLD");
            testCase.verifyEqual(command.targetAzimuth, 120, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.targetTilt, 45, 'AbsTol', 1e-12);
            testCase.verifyFalse(command.motorsEnabled);
            testCase.verifyTrue(command.modeChanged);
            testCase.verifyEqual(state.mode, "DEADBAND_HOLD");
        end

        function testDeadbandResumesTracking(testCase)
            [~, state] = tracker_mode_logic([], makeSun(120, 45), ...
                makeMeasured(100, 30));

            [command, state] = tracker_mode_logic(state, ...
                makeSun(120.3, 45.1), makeMeasured(120.1, 45.0));
            testCase.verifyEqual(command.mode, "DEADBAND_HOLD");

            [command, ~] = tracker_mode_logic(state, ...
                makeSun(121, 45.5), makeMeasured(120.1, 45.0));

            testCase.verifyEqual(command.mode, "DAY_TRACK");
            testCase.verifyEqual(command.targetAzimuth, 121, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.targetTilt, 44.5, 'AbsTol', 1e-12);
            testCase.verifyTrue(command.motorsEnabled);
            testCase.verifyTrue(command.modeChanged);
        end

        function testNightStowMovesToStow(testCase)
            [command, state] = tracker_mode_logic([], ...
                makeSun(300, -5), makeMeasured(150, 40));

            testCase.verifyEqual(command.mode, "NIGHT_STOW");
            testCase.verifyEqual(command.targetAzimuth, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.targetTilt, 0, 'AbsTol', 1e-12);
            testCase.verifyTrue(command.motorsEnabled);
            testCase.verifyEqual(state.mode, "NIGHT_STOW");
        end

        function testNightStowStopsAtStow(testCase)
            [command, ~] = tracker_mode_logic([], ...
                makeSun(300, -5), makeMeasured(0.1, 0.1));

            testCase.verifyEqual(command.mode, "NIGHT_STOW");
            testCase.verifyFalse(command.motorsEnabled);
        end

        function testNightHysteresis(testCase)
            [command, state] = tracker_mode_logic([], ...
                makeSun(90, 3), makeMeasured(90, 80));
            testCase.verifyEqual(command.mode, "DAY_TRACK");

            [command, state] = tracker_mode_logic(state, ...
                makeSun(90, -0.5), makeMeasured(90, 80));
            testCase.verifyEqual(command.mode, "NIGHT_STOW");

            [command, state] = tracker_mode_logic(state, ...
                makeSun(90, 1.5), makeMeasured(90, 80));
            testCase.verifyEqual(command.mode, "NIGHT_STOW");

            [command, ~] = tracker_mode_logic(state, ...
                makeSun(90, 2.5), makeMeasured(90, 80));
            testCase.verifyEqual(command.mode, "DAY_TRACK");
            testCase.verifyEqual(command.targetTilt, 85, 'AbsTol', 1e-12);
        end

        function testCloudHold(testCase)
            [~, state] = tracker_mode_logic([], makeSun(120, 45), ...
                makeMeasured(100, 30));

            [command, ~] = tracker_mode_logic(state, ...
                makeSun(121, 45), makeMeasured(120, 45), ...
                'CloudCover', 0.9);

            testCase.verifyEqual(command.mode, "CLOUD_HOLD");
            testCase.verifyEqual(command.targetAzimuth, 120, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.targetTilt, 45, 'AbsTol', 1e-12);
            testCase.verifyFalse(command.motorsEnabled);
        end

        function testCloudBelowThresholdTracks(testCase)
            [~, state] = tracker_mode_logic([], makeSun(120, 45), ...
                makeMeasured(100, 30));

            [command, ~] = tracker_mode_logic(state, ...
                makeSun(121, 45), makeMeasured(120, 45), ...
                'CloudCover', 0.5);

            testCase.verifyEqual(command.mode, "DAY_TRACK");
            testCase.verifyEqual(command.targetAzimuth, 121, 'AbsTol', 1e-12);
            testCase.verifyTrue(command.motorsEnabled);
        end

        function testFaultLatchesUntilReset(testCase)
            [~, state] = tracker_mode_logic([], makeSun(120, 45), ...
                makeMeasured(100, 30));

            [command, state] = tracker_mode_logic(state, ...
                makeSun(120, 45), makeMeasured(100, 30), 'Fault', true);
            testCase.verifyEqual(command.mode, "FAULT_SAFE");
            testCase.verifyTrue(command.faultLatched);
            testCase.verifyFalse(command.motorsEnabled);

            [command, state] = tracker_mode_logic(state, ...
                makeSun(120, 45), makeMeasured(100, 30));
            testCase.verifyEqual(command.mode, "FAULT_SAFE");
            testCase.verifyTrue(command.faultLatched);

            [command, ~] = tracker_mode_logic(state, ...
                makeSun(120, 45), makeMeasured(100, 30), ...
                'ResetFault', true);
            testCase.verifyEqual(command.mode, "DAY_TRACK");
            testCase.verifyFalse(command.faultLatched);
            testCase.verifyTrue(command.motorsEnabled);
        end

        function testFaultPriorityOverNight(testCase)
            [command, ~] = tracker_mode_logic([], ...
                makeSun(90, -5), makeMeasured(90, 85), 'Fault', true);

            testCase.verifyEqual(command.mode, "FAULT_SAFE");
            testCase.verifyFalse(command.motorsEnabled);
        end

        function testAzimuthErrorWraps(testCase)
            [command, ~] = tracker_mode_logic([], ...
                makeSun(1, 45), makeMeasured(359, 45));

            testCase.verifyEqual(command.mode, "DAY_TRACK");
            testCase.verifyEqual(command.azimuthError, 2, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.targetAzimuth, 1, 'AbsTol', 1e-12);
        end

        function testMechanicalLimits(testCase)
            [command, ~] = tracker_mode_logic([], ...
                makeSun(10, 2), makeMeasured(90, 85), ...
                'MinAzimuth', 90, 'MaxAzimuth', 270, 'MaxTilt', 85);

            testCase.verifyEqual(command.mode, "DEADBAND_HOLD");
            testCase.verifyEqual(command.targetAzimuth, 90, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.targetTilt, 85, 'AbsTol', 1e-12);
            testCase.verifyFalse(command.motorsEnabled);
        end

        function testCustomStowPosition(testCase)
            [command, ~] = tracker_mode_logic([], ...
                makeSun(300, -5), makeMeasured(0, 0), ...
                'StowAzimuth', 180, 'StowTilt', 30);

            testCase.verifyEqual(command.mode, "NIGHT_STOW");
            testCase.verifyEqual(command.targetAzimuth, 180, 'AbsTol', 1e-12);
            testCase.verifyEqual(command.targetTilt, 30, 'AbsTol', 1e-12);
            testCase.verifyTrue(command.motorsEnabled);
        end

        function testInvalidHysteresis(testCase)
            testCase.verifyError(@() tracker_mode_logic([], ...
                makeSun(90, 10), makeMeasured(90, 80), ...
                'SunElevationStow', 2, 'SunElevationResume', 1), ...
                'tracker_mode_logic:InvalidHysteresis');
        end

        function testInvalidAzimuthLimits(testCase)
            testCase.verifyError(@() tracker_mode_logic([], ...
                makeSun(90, 10), makeMeasured(90, 80), ...
                'MinAzimuth', 270, 'MaxAzimuth', 90), ...
                'tracker_mode_logic:InvalidAzimuthLimits');
        end
    end
end

function sun = makeSun(azimuth, elevation)
sun = struct('azimuth', azimuth, 'elevation', elevation);
end

function measured = makeMeasured(azimuth, tilt)
measured = struct('azimuth', azimuth, 'tilt', tilt);
end
