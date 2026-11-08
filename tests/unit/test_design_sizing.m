classdef test_design_sizing < matlab.unittest.TestCase
    % TEST_DESIGN_SIZING  Unit tests for the Gate G2 actuator sizing.
    %
    %   The expected values are the static worst-case sizing results for the
    %   preliminary parameters in PROJECT_CONFIG: 100:1 azimuth gear, 150:1
    %   elevation gear, 3.5 kg*m^2 tilt inertia, and 8.0 kg*m^2 azimuth
    %   inertia.

    % AI-assisted: test cases drafted with OpenCode/DeepSeek.
    % Reviewed and tested by Jhons on 2026-11-09.

    methods (Test)
        function testAzimuthTorqueBalance(testCase)
            cfg = project_config();
            sizing = design_sizing(cfg, 'Verbose', false);
            a = sizing.azimuth;

            expectedInertiaTorque = 8.0 * 0.05;
            expectedOutputTorque = expectedInertiaTorque + 1.0 + 10.0;

            testCase.verifyEqual(a.inertiaTorque, expectedInertiaTorque, ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(a.gravityTorque, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(a.outputTorque, expectedOutputTorque, ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(a.motorTorque, ...
                expectedOutputTorque / (100 * 0.7), 'RelTol', 1e-12);
            testCase.verifyEqual(a.current, a.motorTorque / 0.05, ...
                'RelTol', 1e-12);
        end

        function testElevationGravityTorque(testCase)
            cfg = project_config();
            sizing = design_sizing(cfg, 'Verbose', false);
            e = sizing.elevation;

            expectedGravity = cfg.tracker.panel.mass * 9.81 ...
                * cfg.tracker.panel.centerOfMassOffset;
            expectedOutput = 3.5 * 0.05 + expectedGravity + 1.0 + 10.0;

            testCase.verifyEqual(e.gravityTorque, expectedGravity, ...
                'RelTol', 1e-12);
            testCase.verifyEqual(e.outputTorque, expectedOutput, ...
                'RelTol', 1e-12);
        end

        function testMarginsArePositive(testCase)
            cfg = project_config();
            sizing = design_sizing(cfg, 'Verbose', false);

            testCase.verifyGreaterThan(sizing.azimuth.torqueMargin, 1);
            testCase.verifyGreaterThan(sizing.elevation.torqueMargin, 1);
            testCase.verifyGreaterThan(sizing.azimuth.speedMargin, 1);
            testCase.verifyGreaterThan(sizing.elevation.speedMargin, 1);
            testCase.verifyGreaterThan(sizing.azimuth.currentMargin, 0);
            testCase.verifyGreaterThan(sizing.elevation.currentMargin, 0);
            testCase.verifyGreaterThan(sizing.azimuth.voltageMargin, 0);
            testCase.verifyGreaterThan(sizing.elevation.voltageMargin, 0);
        end

        function testKnownSizingValues(testCase)
            cfg = project_config();
            sizing = design_sizing(cfg, 'Verbose', false);

            testCase.verifyEqual(sizing.azimuth.outputTorque, 11.4, ...
                'RelTol', 1e-12);
            testCase.verifyEqual(sizing.elevation.outputTorque, 17.061, ...
                'RelTol', 1e-9);
            testCase.verifyEqual(sizing.azimuth.current, 3.257142857, ...
                'RelTol', 1e-9);
            testCase.verifyEqual(sizing.elevation.current, 3.249714286, ...
                'RelTol', 1e-9);
        end

        function testGeometricInertiaEstimates(testCase)
            cfg = project_config();
            sizing = design_sizing(cfg, 'Verbose', false);
            panel = cfg.tracker.panel;

            expectedTilt = panel.mass * panel.height^2 / 12;
            expectedAzimuth = panel.mass * ...
                (panel.width^2 + panel.height^2) / 12;

            testCase.verifyEqual(sizing.panel.inertiaTiltGeometric, ...
                expectedTilt, 'RelTol', 1e-12);
            testCase.verifyEqual(sizing.panel.inertiaAzimuthGeometric, ...
                expectedAzimuth, 'RelTol', 1e-12);
            testCase.verifyGreaterThanOrEqual(sizing.panel.inertiaTiltUsed, ...
                expectedTilt);
            testCase.verifyGreaterThanOrEqual( ...
                sizing.panel.inertiaAzimuthUsed, expectedAzimuth);
        end
    end
end
