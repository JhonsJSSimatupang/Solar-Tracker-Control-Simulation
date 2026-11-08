classdef test_energy_model < matlab.unittest.TestCase
    % TEST_ENERGY_MODEL  Unit tests for the clear-sky irradiance and energy.
    %
    %   The reference values follow the Meinel clear-sky model used in
    %   CLEAR_SKY_IRRADIANCE: I0 = 1.353 kW/m^2, tau = 0.70, a = 0.678, and
    %   DHI/DNI = 0.10.

    % AI-assisted: test cases drafted with OpenCode/DeepSeek.
    % Reviewed and tested by Jhons on 2026-11-09.

    methods (Test)
        function testClearSkyAtZenith(testCase)
            irr = clear_sky_irradiance(90);

            expectedDni = 1.353 * 0.7;
            expectedDhi = 0.10 * expectedDni;
            expectedGhi = expectedDni + expectedDhi;

            testCase.verifyEqual(irr.dni, expectedDni, 'RelTol', 1e-12);
            testCase.verifyEqual(irr.dhi, expectedDhi, 'RelTol', 1e-12);
            testCase.verifyEqual(irr.ghi, expectedGhi, 'RelTol', 1e-12);
        end

        function testClearSkyAtNight(testCase)
            irr = clear_sky_irradiance([0; -10; -90]);

            testCase.verifyEqual(irr.dni, zeros(3, 1), 'AbsTol', 1e-12);
            testCase.verifyEqual(irr.dhi, zeros(3, 1), 'AbsTol', 1e-12);
            testCase.verifyEqual(irr.ghi, zeros(3, 1), 'AbsTol', 1e-12);
        end

        function testClearSkyAirMass(testCase)
            irr = clear_sky_irradiance(30);

            expectedDni = 1.353 * 0.7^(2^0.678);
            expectedGhi = expectedDni * 0.5 + 0.10 * expectedDni;

            testCase.verifyEqual(irr.dni, expectedDni, 'RelTol', 1e-12);
            testCase.verifyEqual(irr.ghi, expectedGhi, 'RelTol', 1e-12);
        end

        function testPoaHorizontalEqualsGhi(testCase)
            irr = clear_sky_irradiance(30);
            poa = plane_of_array_irradiance(180, 30, 0, 0, irr);

            testCase.verifyEqual(poa, irr.ghi, 'RelTol', 1e-12);
        end

        function testPoaFacingSun(testCase)
            elevation = 30;
            irr = clear_sky_irradiance(elevation);
            tilt = 90 - elevation;
            poa = plane_of_array_irradiance(180, elevation, 180, tilt, ...
                irr, 'Albedo', 0.20);

            expected = irr.dni ...
                + irr.dhi * (1 + cosd(tilt)) / 2 ...
                + irr.ghi * 0.20 * (1 - cosd(tilt)) / 2;

            testCase.verifyEqual(poa, expected, 'RelTol', 1e-12);
        end

        function testPoaNightIsZero(testCase)
            irr = clear_sky_irradiance(-10);
            poa = plane_of_array_irradiance(180, -10, 0, 0, irr);

            testCase.verifyEqual(poa, 0, 'AbsTol', 1e-12);
        end

        function testEnergyIntegration(testCase)
            time = datetime(2026, 3, 21, 0, 0, 0) + hours(0:1:2);
            pvPower = [1; 1; 1];        % kW
            actuatorPower = [100; 100; 100]; % W
            metrics = energy_metrics(time, pvPower, actuatorPower);

            testCase.verifyEqual(metrics.pvEnergy_kWh, 2, 'RelTol', 1e-12);
            testCase.verifyEqual(metrics.actuatorEnergy_kWh, 0.2, ...
                'RelTol', 1e-12);
            testCase.verifyEqual(metrics.netEnergy_kWh, 1.8, ...
                'RelTol', 1e-12);
            testCase.verifyEqual(metrics.duration_hours, 2, ...
                'RelTol', 1e-12);
        end

        function testDailyDualAxisBeatsFixed(testCase)
            fixed = daily_energy_simulation('Configuration', 'fixed', ...
                'SampleTimeMinutes', 10);
            dual = daily_energy_simulation('Configuration', 'dual-axis', ...
                'SampleTimeMinutes', 10);

            testCase.verifyGreaterThan(fixed.pvEnergy_kWh, 0);
            testCase.verifyGreaterThan(dual.pvEnergy_kWh, ...
                fixed.pvEnergy_kWh);
            testCase.verifyEqual(fixed.pvEnergy_kWh, ...
                fixed.poaEnergy_kWh_per_m2 * 1.6 * 0.18 * 0.85, ...
                'RelTol', 1e-12);
        end

        function testDailyEnergyIsZeroAtNight(testCase)
            dual = daily_energy_simulation('Configuration', 'dual-axis', ...
                'SampleTimeMinutes', 10);
            night = dual.sunElevation <= 0;

            testCase.verifyEqual(dual.pvPower_kW(night), ...
                zeros(nnz(night), 1), 'AbsTol', 1e-12);
        end

        function testDailyComparisonTable(testCase)
            results = compare_daily_energy('SampleTimeMinutes', 20);

            testCase.verifyEqual(height(results), 3);
            testCase.verifyEqual(results.Configuration, ...
                ["Fixed"; "Single-axis azimuth"; "Dual-axis"]);
            testCase.verifyEqual(results.Gain_vs_Fixed_pct(1), 0, ...
                'AbsTol', 1e-12);
            testCase.verifyGreaterThan(results.Gain_vs_Fixed_pct(3), ...
                results.Gain_vs_Fixed_pct(2));
        end
    end
end
