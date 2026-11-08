classdef test_axis_comparison < matlab.unittest.TestCase
    % TEST_AXIS_COMPARISON  Checks for the annual tracker-axis comparison.
    %
    %   The reference values are the 2026 Malang direct-beam proxy computed
    %   with the NOAA/Meeus solar position and the Meinel clear-sky model.

    % AI-assisted: test cases drafted with OpenCode/DeepSeek.
    % Reviewed and tested by Jhons on 2026-11-09.

    methods (Test)
        function testAnnualOrdering(testCase)
            results = compare_tracker_axes('year', 2026, ...
                'timeStepMinutes', 60, 'writeFiles', false);
            energy = results.Energy_kWh_per_m2;

            testCase.verifyGreaterThanOrEqual(energy(4), energy(3) - 1e-6);
            testCase.verifyGreaterThanOrEqual(energy(3), energy(2) - 1e-6);
            testCase.verifyGreaterThanOrEqual(energy(2), energy(1) - 1e-6);
            testCase.verifyGreaterThan(results.Gain_vs_Fixed_pct(4), 0);
        end

        function testOptimalTiltRanges(testCase)
            results = compare_tracker_axes('year', 2026, ...
                'timeStepMinutes', 120, 'writeFiles', false);

            testCase.verifyGreaterThanOrEqual(results.OptimalTilt_deg(1), 0);
            testCase.verifyLessThanOrEqual(results.OptimalTilt_deg(1), 30);
            testCase.verifyGreaterThanOrEqual(results.OptimalTilt_deg(2), 30);
            testCase.verifyLessThanOrEqual(results.OptimalTilt_deg(2), 60);
        end

        function testKnownAnnualProxyValues(testCase)
            results = compare_tracker_axes('year', 2026, ...
                'timeStepMinutes', 30, 'writeFiles', false);

            testCase.verifyEqual(results.Energy_kWh_per_m2(1), 2276.58, ...
                'RelTol', 0.01);
            testCase.verifyEqual(results.Energy_kWh_per_m2(4), 3264.54, ...
                'RelTol', 0.01);
        end

        function testTiltSweepDetails(testCase)
            [results, details] = compare_tracker_axes('year', 2026, ...
                'timeStepMinutes', 120, 'writeFiles', false);

            testCase.verifySize(details.fixedEnergyCurve, [61 1]);
            testCase.verifySize(details.azimuthEnergyCurve, [61 1]);
            testCase.verifyEqual(max(details.fixedEnergyCurve), ...
                results.Energy_kWh_per_m2(1), 'RelTol', 1e-12);
            testCase.verifyEqual(max(details.azimuthEnergyCurve), ...
                results.Energy_kWh_per_m2(2), 'RelTol', 1e-12);
        end
    end
end
