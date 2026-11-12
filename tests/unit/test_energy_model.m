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

            % The net gain must be lower than the PV gain, because the
            % tracker pays for its own motion, and it must still be positive.
            testCase.verifyEqual(results.ActuatorEnergy_kWh(1), 0, ...
                'AbsTol', 1e-12);
            testCase.verifyGreaterThan(results.ActuatorEnergy_kWh(3), 0);
            testCase.verifyLessThan(results.NetGain_vs_Fixed_pct(3), ...
                results.Gain_vs_Fixed_pct(3));
            testCase.verifyGreaterThan(results.NetGain_vs_Fixed_pct(3), 0);
        end

        function testActuatorHoldingCurrent(testCase)
            % At tilt 0 the panel centre of mass gives m*g*L = 5.886 N*m.
            % With the 150:1, 70 % elevation gear and Kt = 0.05 N*m/A the
            % motor needs 1.12 A, and Ra = 1.2 ohm gives about 1.5 W.
            cfg = project_config();
            p.elevation.gearRatio = cfg.tracker.elevation.gearRatio;
            p.elevation.gearEfficiency = ...
                cfg.tracker.elevation.gearEfficiency;
            p.elevation.staticFriction = 0;
            p.elevation.torqueConstant = ...
                cfg.actuator.elevation.torqueConstant;
            p.elevation.backEmfConstant = ...
                cfg.actuator.elevation.backEmfConstant;
            p.elevation.armatureResistance = ...
                cfg.actuator.elevation.armatureResistance;
            p.elevation.ratedVoltage = cfg.actuator.elevation.ratedVoltage;
            p.elevation.currentLimit = cfg.actuator.elevation.currentLimit;
            p.elevation.gravityTorqueAmplitude = cfg.tracker.panel.mass ...
                * 9.81 * cfg.tracker.panel.centerOfMassOffset;
            p.azimuth = p.elevation;
            p.azimuth.gravityTorqueAmplitude = 0;
            p.azimuth.disturbanceTorque = 0;

            time = datetime(2026, 3, 21, 0, 0, 0) + minutes(0:1);
            [power, details] = tracker_actuator_energy( ...
                time, [0; 0], [0; 0], p);

            testCase.verifyEqual(details.elevation.current_A(1), ...
                1.1211, 'AbsTol', 1e-3);
            testCase.verifyEqual(power(1), 1.508, 'AbsTol', 1e-2);
        end
    end
end
