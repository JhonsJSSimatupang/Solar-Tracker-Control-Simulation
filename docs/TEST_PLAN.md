# 🧪 Test Plan

## Solar Tracker Control Simulation

> **Status:** Unit tests implemented and passing (50/50 on 2026-11-09).
> The baseline Simulink model runs end-to-end and writes tracking metrics.
> Model, integration, scenario, and regression tests are the next stage.

This document defines how the simulation is verified and validated. It covers
test levels, test cases, pass criteria, and result recording.

---

## 1. Objectives

- Verify that each subsystem meets its requirements.
- Validate the integrated dual-axis system against physical expectations.
- Ensure results are reproducible.
- Provide evidence for the traceability matrix.

---

## 2. Test Environment

Two installations were used. Both were exercised with the same commands.

| Item | Primary | Secondary |
|---|---|---|
| MATLAB version | R2026a Update 5 (26.1.0.3346908) | R2026b Update 1 (26.2.0.3433840) |
| Simulink version | R2026a (26.1) | R2026b (26.2) |
| Installed products | MATLAB, Simulink, Simscape, Simscape Multibody, Simscape Electrical, Control System Toolbox | MATLAB, Simulink, Simscape, Simscape Battery, Simscape Electrical, Control System Toolbox |
| Optional but not installed | Simulink Control Design, Stateflow, Simulink Test, Simulink Coverage | Simscape Multibody, Simulink Control Design, Stateflow, Simulink Test, Simulink Coverage |
| Operating system | Windows 11 Home Single Language (build 26200) | Windows 11, PCWIN64 |
| Reference data | NOAA Solar Calculator, NREL SPA, NASA POWER, BMKG | same |

Neither installation has Simulink Test, which is why the model-level tests
(§7) are driven by MATLAB scripts rather than the Simulink Test Manager.

### 2.1 Cross-version check (2026-11-10 / 2026-11-11)

| Check | R2026a | R2026b | Verdict |
|---|---|---|---|
| Unit suite | 50/50 pass | 50/50 pass | identical |
| `run_project` azimuth RMSE | 0.1866° | 0.18664° | identical |
| `run_project` tilt RMSE | 0.0778° | 0.07784° | identical |
| `run_project` azimuth max | 3.9422° | 3.9422° | identical |
| `run_project` tilt max | 1.3231° | 1.3231° | identical |
| `verify_axis_plant` | 3/3 pass | 3/3 pass | identical |

The fixed-step `ode4` solver produces bit-identical results across the two
releases, which supports the reproducibility requirement.

### 2.2 Installation differences that affect tooling

- **JUnit XML output plugin.** The R2026b installation is trimmed and ships
  without `matlab.unittest.plugins.XMLOutputPlugin`. `run_all_tests` therefore
  detects the plugin before using it and reports
  `no XML plugin in this installation` instead of failing the suite. The
  summary CSV is always written.
- **Simscape Multibody.** Installed on R2026a but not on R2026b. It is not
  used, so the results are unaffected; this was the reason for moving it to the
  optional list (DEF-008).
- **Resource headroom.** Compiling a Simscape network needs several gigabytes
  of commit charge. On a machine with under 1 GB of free commit, model
  compilation fails with `Memory allocation error` or a process exit code of
  `0xc000012d` (`STATUS_COMMITMENT_LIMIT`), and a full disk makes Simulink
  report low available space and drop logged data. These are host conditions,
  not code defects; the checks in this document were recorded on runs where
  both disk and memory were adequate. The disk half of this is now avoided in
  the tooling: `configure_sdi_preferences` turns off SDI archiving, so the
  Simulation Data Inspector cannot delete runs or stop recording mid-simulation
  when space runs low (DEF-011). Memory headroom is still a host requirement.

All tests must run from the repository root using `run_all_tests.m`,
`run_project.m`, or a documented test script.

`tests/run_everything.m` is the widest entry point: it executes every
executable file in dependency order (pure functions, both model builds, axis
checks, plant validation, baseline simulation, both energy comparisons, the
unit suite) and finishes with `run_all_tests`. It reports one pass or fail line
per step and keeps going after a failure, so a single broken step does not hide
the state of the rest. The run takes several minutes; a full pass is 16 steps.

---

## 3. Test Levels

| Level | Purpose | Location | Status |
|---|---|---|---|
| Static | Detect code and model quality issues | Code Analyzer, Model Advisor | Code Analyzer available; Model Advisor pending |
| Unit | Verify individual functions | `tests/unit/` | Implemented, 50/50 passing |
| Model | Verify controllers, actuators, and mechanics | `tests/model/` | Baseline model runs; Simscape tests pending |
| Integration | Verify the full tracking chain | `tests/integration/` | Pending Simscape model |
| Scenario | Verify behavior under operating conditions | `tests/scenarios/` | Pending Simscape model |
| Regression | Detect unintended changes | `tests/regression/` | Pending baseline |
| Robustness | Verify behavior under uncertainty | `tests/robustness/` | Pending model |
| Reproducibility | Verify clean-clone execution | Manual checklist | Partially verified for unit tests |

---

## 4. Test Data

| Source | Use |
|---|---|
| NOAA Solar Calculator | Reference azimuth and elevation |
| NREL SPA | Reference solar position and validation |
| NASA POWER | Irradiance and weather data |
| BMKG | Local Indonesian weather data (optional) |
| Simscape example | Baseline azimuth mechanical model |

A small synthetic dataset is generated by the scripts (solar position and
clear-sky irradiance); no external download is required to run the tests.

---

## 5. Static Tests

| ID | Test | Tool | Pass criterion | Status |
|---|---|---|---|---|
| ST-01 | Code Analyzer on all `.m` files | `checkcode` | No errors; warnings reviewed | Pass (settings-file warning only) |
| ST-02 | Model Advisor on the main model | Model Advisor | No unresolved errors | Pending model |
| ST-03 | No hard-coded absolute paths | Manual review | All paths relative or derived from `projectRoot` | Pass |
| ST-04 | No generated files committed | Git review | `slprj/`, `*.slxc`, autosave files absent | Pass (ignored and removed) |

---

## 6. Unit Tests

### 6.1 Implemented — solar position and geometry

All tests are in `tests/unit/test_solar_position.m`.

| ID | Test method | Input | Pass criterion | Result |
|---|---|---|---|---|
| UT-SPA-01 | `testNrelSpaGoldenExample` | Golden, CO, 2003-10-17 12:30:30 MST | Azimuth 194.340241° ± 0.01°; geometric elevation 39.872046° ± 0.01°; equation of time 14.64 min ± 0.02 min | Pass |
| UT-SPA-02 | `testTimeZoneEquivalence` | Malang, unzoned local time vs `Asia/Jakarta` time | Azimuth, elevation, and Julian date agree within 1e-12 | Pass |
| UT-SPA-03 | `testMalangDayAndNight` | Malang, 2026-03-21 noon and midnight | Daytime elevation > 70°; midnight elevation < 0° | Pass |
| UT-SPA-04 | `testMorningSunIsEastAndAfternoonSunIsWest` | Malang, 09:00 and 15:00 | Morning azimuth in (0°, 180°); afternoon azimuth in (180°, 360°) | Pass |
| UT-SPA-05 | `testEquinoxNoonElevation` | Malang, 2026-03-21 | Maximum elevation equals `90 - |latitude|` within 1° | Pass |
| UT-SPA-06 | `testVectorInputReturnsStructArray` | 7-element datetime vector | Output has one element per input; azimuth in [0°, 360°); finite elevation | Pass |
| UT-SPA-07 | `testInvalidSiteCoordinates` | Latitude 91°, longitude 181°, time zone 15 | `MATLAB:validators:mustBeBetweenScalarBounds` | Pass |
| UT-COORD-01 | `testSolarVectorCardinalDirections` | Cardinal directions | Unit vectors match the ENU definition within 1e-12 | Pass |
| UT-COORD-02 | `testPanelNormalDefinition` | Tilt 0°, 45°, 90° | Tilt 0° faces up; tilt 90° faces the panel azimuth | Pass |
| UT-COORD-03 | `testAngleOfIncidence` | Aligned and perpendicular cases | Incidence angle matches the hand calculation within 1e-12 | Pass |

### 6.2 Implemented — target angles

All tests are in `tests/unit/test_target_angles.m`.

| ID | Test method | Input | Pass criterion | Result |
|---|---|---|---|---|
| UT-TGT-01 | `testDaytimeConversion` | Sun azimuth 120°, elevation 45° | Target azimuth 120°; target tilt 45°; mode `DAY_TRACK` | Pass |
| UT-TGT-02 | `testNightStow` | Elevation −5° and 0° | Stow azimuth 0°; stow tilt 0°; mode `NIGHT_STOW` | Pass |
| UT-TGT-03 | `testMechanicalClamping` | Azimuth 10°, elevation 85°, limits 90°–270° and 10°–80° | Target azimuth 90°; target tilt 10° | Pass |
| UT-TGT-04 | `testCustomStowPosition` | Elevation −10°, stow 180°/85° | Target equals the custom stow position | Pass |
| UT-TGT-05 | `testVectorInput` | Three sun positions | Three targets; tilts 60°, 0°, 80°; tracking flags correct | Pass |

### 6.3 Implemented — axis comparison

All tests are in `tests/unit/test_axis_comparison.m`.

| ID | Test method | Input | Pass criterion | Result |
|---|---|---|---|---|
| UT-ENERGY-01 | `testAnnualOrdering` | Malang 2026, 60-minute sampling | Dual-axis ≥ horizontal N-S ≥ azimuth ≥ fixed (within 1e-6); dual-axis gain > 0 | Pass |
| UT-ENERGY-02 | `testOptimalTiltRanges` | Malang 2026, 120-minute sampling | Fixed optimum in 0°–30°; azimuth optimum in 30°–60° | Pass |
| UT-ENERGY-03 | `testKnownAnnualProxyValues` | Malang 2026, 30-minute sampling | Fixed 2276.58 kWh/m² ± 1%; dual-axis 3264.54 kWh/m² ± 1% | Pass |
| UT-ENERGY-04 | `testTiltSweepDetails` | Malang 2026, 120-minute sampling | Both curves are 61×1; curve maximum equals the reported optimum | Pass |

### 6.4 Implemented — actuator sizing

All tests are in `tests/unit/test_design_sizing.m`.

| ID | Test method | Input | Pass criterion | Result |
|---|---|---|---|---|
| UT-SIZE-01 | `testAzimuthTorqueBalance` | Default parameters | Output torque 11.4 N·m; motor torque 11.4/(100×0.7); current consistent | Pass |
| UT-SIZE-02 | `testElevationGravityTorque` | Default parameters | Gravity torque 5.886 N·m; output torque 17.061 N·m | Pass |
| UT-SIZE-03 | `testMarginsArePositive` | Default parameters | Torque, speed, current, and voltage margins all positive | Pass |
| UT-SIZE-04 | `testKnownSizingValues` | Default parameters | Output torque, motor current within 1e-9 relative tolerance of the G2 values | Pass |
| UT-SIZE-05 | `testGeometricInertiaEstimates` | Default parameters | Thin-plate estimates 2.56 and 3.56 kg·m²; used values not below the estimates | Pass |

### 6.5 Implemented — energy model

All tests are in `tests/unit/test_energy_model.m`.

| ID | Test method | Input | Pass criterion | Result |
|---|---|---|---|---|
| UT-ENERGY-05 | `testClearSkyAtZenith` | Sun elevation 90° | DNI 0.9471 kW/m²; DHI 0.09471; GHI 1.04181 | Pass |
| UT-ENERGY-06 | `testClearSkyAtNight` | Sun elevation 0°, −10°, −90° | DNI, DHI, and GHI are zero | Pass |
| UT-ENERGY-07 | `testClearSkyAirMass` | Sun elevation 30° | DNI matches `1.353 × 0.7^(2^0.678)` | Pass |
| UT-ENERGY-08 | `testPoaHorizontalEqualsGhi` | Horizontal panel, elevation 30° | POA equals GHI | Pass |
| UT-ENERGY-09 | `testPoaFacingSun` | Panel normal aligned with the sun | POA matches the isotropic-sky hand calculation | Pass |
| UT-ENERGY-10 | `testPoaNightIsZero` | Sun elevation −10° | POA is zero | Pass |
| UT-ENERGY-11 | `testEnergyIntegration` | 1 kW PV and 100 W actuator for 2 h | PV 2 kWh; actuator 0.2 kWh; net 1.8 kWh | Pass |
| UT-ENERGY-12 | `testDailyDualAxisBeatsFixed` | Malang equinox, 10-minute sampling | Dual-axis daily energy > fixed; PV energy consistent with POA | Pass |
| UT-ENERGY-13 | `testDailyEnergyIsZeroAtNight` | Malang equinox, 10-minute sampling | PV power is zero whenever the sun is below the horizon | Pass |
| UT-ENERGY-14 | `testDailyComparisonTable` | Three configurations | Three rows; fixed gain 0; dual-axis gain > azimuth gain; net gain > 0 and below PV gain | Pass |
| UT-ENERGY-15 | `testActuatorHoldingCurrent` | Tilt 0°, no motion, 150:1 gear | Holding current 1.1211 A and power 1.508 W | Pass |

### 6.6 Implemented — mode and deadband logic

All tests are in `tests/unit/test_mode_logic.m`.

| ID | Test method | Input | Pass criterion | Result |
|---|---|---|---|---|
| UT-STRAT-01 | `testDayTrack` | Sun 120°/45°, panel 100°/30° | `DAY_TRACK`; target 120°/45°; motors enabled | Pass |
| UT-STRAT-02 | `testDeadbandHold` | Sun moves 0.3°; both errors ≤ 0.5° | `DEADBAND_HOLD`; target held; motors disabled | Pass |
| UT-STRAT-03 | `testDeadbandResumesTracking` | After a hold, azimuth error 0.9° | `DAY_TRACK`; target updated; motors enabled | Pass |
| UT-STRAT-04 | `testNightStowMovesToStow` | Sun elevation −5°, panel 150°/40° | `NIGHT_STOW`; target 0°/0°; motors enabled | Pass |
| UT-STRAT-05 | `testNightStowStopsAtStow` | Panel within 0.1° of the stow position | `NIGHT_STOW`; motors disabled | Pass |
| UT-STRAT-06 | `testNightHysteresis` | 3° → −0.5° → 1.5° → 2.5° | Track, stow, remain stowed, then resume above 2° | Pass |
| UT-STRAT-07 | `testCloudHold` | Cloud cover 0.9 | `CLOUD_HOLD`; target held; motors disabled | Pass |
| UT-STRAT-08 | `testCloudBelowThresholdTracks` | Cloud cover 0.5 | `DAY_TRACK`; motors enabled | Pass |
| UT-STRAT-09 | `testFaultLatchesUntilReset` | Fault, then clear, then reset | `FAULT_SAFE` remains latched; reset resumes tracking | Pass |
| UT-STRAT-10 | `testFaultPriorityOverNight` | Fault and night together | `FAULT_SAFE` takes priority; motors disabled | Pass |
| UT-STRAT-11 | `testAzimuthErrorWraps` | Sun 1°, panel 359° | Azimuth error +2°, not −358° | Pass |
| UT-STRAT-12 | `testMechanicalLimits` | Azimuth 10°, tilt 88°, limits 90°–270° and 85° | Targets clamped to 90°/85° | Pass |
| UT-STRAT-13 | `testCustomStowPosition` | Stow 180°/30° | `NIGHT_STOW` targets 180°/30° | Pass |
| UT-STRAT-14 | `testInvalidHysteresis` | Resume 1° below stow 2° | `tracker_mode_logic:InvalidHysteresis` | Pass |
| UT-STRAT-15 | `testInvalidAzimuthLimits` | Minimum 270°, maximum 90° | `tracker_mode_logic:InvalidAzimuthLimits` | Pass |

### 6.7 Planned unit tests

| ID | Test | Pass criterion |
|---|---|---|
| UT-CTRL-01 | PID proportional and derivative terms | Output matches the discrete PID equation |
| UT-CTRL-02 | PID anti-windup | Integral stops growing while the output is saturated |
| UT-CTRL-03 | PID output and rate limits | Command stays inside the voltage and slew-rate limits |

### 6.8 Execution evidence

Command:

```matlab
addpath('tests');
results = run_unit_tests();
assertSuccess(results);
```

Result on 2026-11-09:

```text
Running test_axis_comparison
....
Running test_design_sizing
.....
Running test_energy_model
...........
Running test_mode_logic
.......... .....
Running test_solar_position
..........
Running test_target_angles
.....

Passed: 50, Failed: 0, Incomplete: 0
```

---

## 7. Model Tests

| ID | Test | Pass criterion |
|---|---|---|
| MT-ACT-01 | Azimuth motor open-loop response | Speed and direction match the motor equations |
| MT-ACT-02 | Azimuth actuator saturation | Voltage and current limited to the specified range |
| MT-ACT-03 | Elevation motor open-loop response | Speed and direction match the motor equations, including gravity torque |
| MT-ACT-04 | Elevation actuator saturation | Voltage and current limited to the specified range |
| MT-MECH-01 | Azimuth motion range | Stops at the mechanical limits; no singularities |
| MT-MECH-02 | Azimuth gear ratio | Output angle = input angle / gear ratio within 1% |
| MT-MECH-03 | Elevation motion range | Stops at 0° and 85°; no singularity in the operating range |
| MT-MECH-04 | Elevation gear ratio | Output angle = input angle / gear ratio within 1% |
| MT-CTRL-01 | Azimuth step response | Settling ≤ 15 s, overshoot ≤ 10%, steady-state error ≤ 0.2° |
| MT-CTRL-02 | Azimuth ramp tracking | Error within the limit defined at Gate G2 |
| MT-CTRL-03 | Azimuth disturbance rejection | Recovers within the specified time |
| MT-CTRL-04 | Elevation step response | Settling ≤ 15 s, overshoot ≤ 10%, steady-state error ≤ 0.2° |
| MT-CTRL-05 | Elevation gravity compensation | Steady-state error ≤ 0.2° across the tilt range |
| MT-CTRL-06 | Elevation disturbance rejection | Recovers within the specified time |

> Numerical pass criteria will be confirmed at Gate G2 after the plant model
> exists.

### 7.1 Implemented — explicit axis plant

`models/verify_axis_plant.m` builds one axis from the parameters in
`project_config` and compares the response with closed-form results. Coulomb
friction is set to a negligible value so the checks stay linear and the
comparisons are exact.

| ID | Test | Closed-form reference | Result |
|---|---|---|---|
| MT-ACT-01 | No-load steady-state speed at 24 V | `w = Kt*V/(Kt*Ke + B*Ra)` = 458.015 rad/s | Pass — 457.955 rad/s (0.01%) |
| MT-ACT-02 | Armature current ceiling | `i <= currentLimit` = 5 A | Pass — 5.000 A |
| MT-ACT-05 | Speed rise time | `tau = J_eq*Ra/(Kt*Ke + B*Ra)` = 0.371 s | Pass — 0.371 s (0.1%) |
| MT-ACT-06 | Bus voltage ceiling (T4) | Command 1.25·Vbus; applied voltage must clamp to Vbus = 24 V | Pass — \|v\|max = 24.000 V, \|i\|max = 5.000 A |

The torque ceiling is enforced by clamping the applied voltage to
`Ke*omega ± Ra*currentLimit`, which is exactly equivalent to `|i| <= i_limit`
and adds no algebraic loop. The `VbusLim` saturation block then clamps the
result to the supply rails, so a controller demand above 24 V cannot reach the
motor.

> Verified 2026-11-11 on R2026b Update 1 (T1–T4, 4/4 pass).

### 7.2 Implemented — closed-loop plant validation

`models/validate_tracker_plant.m` closes two PID loops around the Simscape
axis plants in `models/solar_tracker_plant.slx` and runs two scenarios: a
30° azimuth / 45° tilt step, and a two-hour tracking window on the configured
day. The first 60 s of the tracking run is a homing ramp from the horizontal
park position, so the homing move does not flatter the metrics. Artifacts:
`results/metrics/plant_validation.csv` and
`results/figures/plant_validation.png`.

| ID | Test | Pass criterion | Result |
|---|---|---|---|
| MT-CTRL-01 | Azimuth step response | Overshoot ≤ 10 %, settling ≤ 20 s, SSE ≤ 0.2° | Pass — 8.07 %, 7.43 s, 0.011° |
| MT-CTRL-02 | Azimuth tracking RMSE | ≤ 0.5° | Pass — 0.0108° |
| MT-CTRL-04 | Elevation step response | Overshoot ≤ 10 %, settling ≤ 20 s, SSE ≤ 0.2° | Pass — 6.84 %, 7.18 s, 0.007° |
| MT-CTRL-05 | Elevation tracking RMSE | ≤ 0.5° | Pass — 0.0099° |
| MT-CTRL-07 | Peak armature current | ≤ 1.02 × currentLimit (5.1 A) | Pass — 5.000 A on both axes |
| MT-CTRL-08 | Rise time 10–90 % | ≤ 10 s | Pass — 0.48 s azimuth, 0.57 s tilt |
| MT-CTRL-09 | Tracking maximum error | ≤ 2.0° | Pass — 0.347° azimuth, 0.310° tilt |

> Verified 2026-11-11 on R2026b Update 1. 14 of 14 checks passed. The
> tracking window is two hours, not a full day: the control step is 10 ms, so
> 24 h would need 8.6 million fixed steps. The daily energy study stays on the
> reduced-order model in `models/solar_tracker.slx`.

---

## 8. Integration Tests

| ID | Test | Pass criterion |
|---|---|---|
| IT-01 | Full-day simulation | Completes 24 h without solver errors |
| IT-02 | Sun-to-panel chain | Azimuth and tilt follow the sun within 0.5° RMS |
| IT-03 | Mode changes | Day, night, and cloudy transitions occur without errors |
| IT-04 | Energy calculation | Captured and actuator energy are positive during daylight; net energy is reported |
| IT-05 | Axis coupling | Azimuth motion does not excite an elevation error above 0.5° |

---

## 9. Scenario Tests

| ID | Scenario | Pass criterion |
|---|---|---|
| SC-01 | Clear sky | RMS azimuth and tilt error ≤ 0.5°; energy gain documented |
| SC-02 | Partly cloudy | Controller remains stable; mode logic behaves as designed |
| SC-03 | Rain or heavy cloud | Tracker holds position or stows; no unnecessary movement |
| SC-04 | Sunrise and sunset | No abrupt motion; limits respected |
| SC-05 | Night | Tracker at stow position; no actuator command |
| SC-06 | High wind (if modeled) | Tracker enters safe mode |
| SC-07 | Motor or sensor fault | Fault detected; both axes enter a safe state |

---

## 10. Regression Tests

| ID | Test | Pass criterion |
|---|---|---|
| RT-01 | Baseline metrics | RMSE, settling time, and energy within 1% of the recorded baseline |
| RT-02 | Baseline figures | Regenerated figures match the stored figures within tolerance |
| RT-03 | Parameter sweep | Results are monotonic or explainable |
| RT-04 | Axis comparison | `results/metrics/axis_comparison.csv` matches the recorded baseline within 1% |

The regression baseline is recorded at Gate G7 and stored in
`results/metrics/`.

---

## 11. Robustness Tests

| ID | Test | Pass criterion |
|---|---|---|
| RB-01 | Parameter variation | Stable for ±10% motor and mechanical parameters on both axes |
| RB-02 | Sensor noise | Tracking error remains within the specified limit |
| RB-03 | Disturbance | Recovers to the target within the specified time |
| RB-04 | Monte Carlo | 95% of runs meet the tracking requirement |

The number of Monte Carlo runs and the parameter distributions will be defined
at Gate G2.

---

## 12. Reproducibility Tests

| ID | Test | Pass criterion |
|---|---|---|
| RP-01 | Clean clone | `run_project.m` runs without edits |
| RP-02 | Clean MATLAB | No dependency on the developer's workspace |
| RP-03 | Expected outputs | Figures and metrics match the documented results |
| RP-04 | Runtime | Full simulation completes within the documented time |

---

## 13. Traceability Matrix

| Requirement | Design element | Test case | Result | Status |
|---|---|---|---|---|
| FR-01 | `src/sun_position/solar_position.m` | UT-SPA-01…07 | 10/10 pass | Verified (unit) |
| FR-02 | `src/sun_position/target_angles.m` | UT-TGT-01…05 | 5/5 pass | Verified (unit) |
| FR-03 | `src/controllers/tracker_mode_logic.m` | UT-STRAT-01…15 | 15/15 pass | Verified (unit) |
| FR-04 | Azimuth PID | MT-CTRL-01…03 | TBD | Open |
| FR-05 | Elevation PID | MT-CTRL-04…06 | TBD | Open |
| FR-06 | Integrated tracking chain | IT-02, IT-05 | TBD | Open |
| FR-07 | Actuator models | MT-ACT-01…04 | TBD | Open |
| FR-08 | Two-axis mechanical model | MT-MECH-01…04 | TBD | Open |
| G2 sizing | `src/analysis/design_sizing.m` | UT-SIZE-01…05 | 5/5 pass | Verified (unit) |
| FR-09 | Irradiance model | UT-ENERGY-05…10 | 6/6 pass | Verified (unit) |
| FR-10 | Energy accounting | UT-ENERGY-11…15, IT-04 | 5/5 pass (unit); daily net energy in `results/metrics/daily_energy_comparison.csv` | Verified |
| FR-11 | Scenario set | SC-01…07 | TBD | Open |
| FR-12 | `tracker_mode_logic.m` safe state; sensor/motor fault detection | UT-STRAT-09, UT-STRAT-10, SC-07 | Safe-state unit tests pass; fault detection pending | Partially verified |
| FR-13 | `run_project.m` | RP-01…04 | TBD | Open |
| NFR-01 | `run_project.m` | RP-01 | TBD | Open |
| NFR-02 | README and dependencies | RP-02 | TBD | Open |
| NFR-03 | `project_config.m`, `setup_project.m` | ST-03 | TBD | Open |
| NFR-04 | Documentation and results | RP-03 | TBD | Open |
| NFR-05 | Runtime budget | RP-04 | TBD | Open |
| NFR-06 | Code Analyzer / Model Advisor | ST-01, ST-02 | TBD | Open |
| NFR-07 | Documentation set | Manual review | TBD | Open |
| NFR-08 | AI usage log | Manual review | TBD | Open |
| NFR-09 | Synthetic inputs generated in code | RP-02 | No download required | Verified |
| NFR-10 | LICENSE | Manual review | Correct copyright holder | Verified |

---

## 14. Defect Log

| ID | Date | Test case | Description | Severity | Status | Resolution |
|---|---|---|---|---|---|---|
| DEF-001 | 2026-11-09 | UT-SPA-01 | Equation-of-time formula returned radians but was treated as degrees; azimuth error about 4.6°. | High | Closed | Wrapped the equation-of-time expression in `rad2deg`; golden case now passes. |
| DEF-002 | 2026-11-09 | UT-COORD-02 | `panel_normal` defined tilt 0° as facing north instead of facing up. | High | Closed | Redefined the normal as `[sin(tilt)·sin(az); sin(tilt)·cos(az); cos(tilt)]`. |
| DEF-003 | 2026-11-09 | All unit tests | Test methods used `self.` instead of `testCase.`, so the properties were undefined. | Medium | Closed | Replaced `self.` with `testCase.`. |
| DEF-004 | 2026-11-09 | UT-ENERGY-01 | `solar_vector` and `panel_normal` did not expand a scalar angle against a vector. | Medium | Closed | Added scalar-expansion handling and a size-mismatch error. |
| DEF-005 | 2026-11-10 | MT-ACT-02 | `build_axis_plant` declares `Vbus` as a required parameter and `verify_axis_plant` supplies 24 V, but the value is never applied. The commanded voltage is limited by the current window only, so a controller output above the bus voltage would be accepted. | Medium | Closed | Added a `VbusLim` saturation block after the current window and before the controlled voltage source, wired to both `S2PS_V` and the `voltage_V` output. Added test T4, which commands 30 V through a 24 V bus and requires the measured voltage to be exactly 24 V. Passes on R2026b. |
| DEF-006 | 2026-11-10 | Static review | `build_solar_tracker_model` uses only `Kp`, `Ki`, `outputMin`, and `outputMax`. Four parameters declared in `project_config` are never read: `cfg.controller.*.Kd`, `cfg.controller.*.rateLimit`, `cfg.controller.*.filterCoefficient`, and `cfg.simulation.controllerSampleTime`. The model is a PI, not a PID, and has no rate limit. | Low | Closed | `models/build_tracker_plant_model.m` implements a full PID: proportional and integral paths, a filtered derivative on the measurement `Kd·wf·s/(s+wf)`, an integrator clamped to the voltage limit, and a rate limiter. All four parameters are now read. The reduced-order baseline keeps the documented PI simplification. |
| DEF-007 | 2026-11-10 | Static review | The model runs `Solver = ode4` with `FixedStep = 1 s`, so the PI controller updates once per second. `cfg.simulation.controllerSampleTime` states 0.01 s (100 Hz) and the system design documents a 10 ms loop, so the documented bandwidth is not what the model delivers. | Medium | Closed | `solar_tracker_plant.slx` runs a 10 ms fixed step with Simscape local solvers at the same rate, so the controller now updates at the documented rate. The reduced-order baseline is deliberately left at 1 s for the 24 h energy study, and this is stated in the design document. |
| DEF-008 | 2026-11-10 | Environment check | `check_environment` demanded Simscape Multibody and Control System Toolbox as required products. Neither is used: the axes are modelled with lumped-parameter rotational dynamics, and no file references Control System Toolbox. A user with a complete installation for this project was told the environment was incomplete. | Medium | Closed | Moved both to `optionalProducts` and documented why Multibody is deliberately not used. Now only MATLAB, Simulink, Simscape, and Simscape Electrical are reported as required. |
| DEF-009 | 2026-11-10 | MT-ACT-01…05 | Running `verify_axis_plant` without the Simscape blocks available failed with `Simulink:Commands:InvBlockSpecifier: There is no block named 'nesl_utility/Simulink-PS Converter'`, which does not indicate the real cause. | Low | Closed | Added an explicit product check at the start that names the missing product and states which entry points do not need it. Exercised while the product was not reported as installed. |
| DEF-010 | 2026-11-11 | RP-01 | `run_project` could not be called twice in one MATLAB session. Writing the target inputs to the model workspace marks the model as changed, so the second call failed with `run_project:UnsavedModel`. This broke the reproducibility check and any repeated batch use. | High | Closed | Clear the model dirty flag immediately after `sim`, since the workspace data is regenerated on every run. Reproducibility check now runs two consecutive simulations in one session. |
| DEF-011 | 2026-11-12 | MT-VALID-01…14 | On a host with under 1 GB free disk space, the plant validation failed with `MATLAB:badsubscript` while reading the logged dataset. The Simulation Data Inspector deletes archived runs and then disables recording of all data when space runs out, so the logging structure the validation expects is incomplete. The reported error pointed at the analysis code rather than at the host. | Medium | Closed | Added `src/initialization/configure_sdi_preferences.m`, which turns off SDI auto-archive and sets the archive run limit to zero, and called it from `setup_project` and from the start of `run_all_tests`. The first version guarded the calls with `exist` and was silently skipped, because `exist` returns 0 for a package method; the guard is now a `try`/`catch` and the effect is asserted by reading the preferences back (0 and 0). Full suite then passed 6/6 stages and 50/50 unit tests with no low-disk warning. |
| DEF-012 | 2026-11-12 | Model rebuild | Both model builders saved the `.slx` and left it open in a modified state. A later `close_system` in the same session then raised `Unable to close the model 'solar_tracker' because it has been changed`, which reads like a model error in the middle of an unrelated test run. | Low | Closed | Added `close_system(modelName, 0)` immediately after `save_system` in `build_solar_tracker_model` and `build_tracker_plant_model`. Verified by rebuilding both models and running the axis checks and the plant validation in one session: no close warning, 4/4 and 14/14 still pass. |
| DEF-013 | 2026-11-12 | MT-ACT-01…04 | `verify_axis_plant` built its temporary model with the fixed name `axis_plant_test`, so Simulink warned that the name was shadowing a workspace variable or a file already on the path. The warning appears before the checks and looks like a fault in the project. | Low | Closed | The temporary model name now gets a unique suffix from `tempname`, so it cannot collide with anything in the workspace or on the path. Verified by creating a variable literally named `axis_plant_test` and calling the function twice: no warning, 4/4 both times. |

---

## 15. Results Recording

- Store figures in `results/figures/`.
- Store metrics in `results/metrics/` (CSV or MAT).
- Use the naming convention `<test-id>_<description>_<date>`.
- Record the MATLAB version and model version with each result.
- Do not overwrite a baseline result; create a new version.

Current reproducible outputs:

| File | Content |
|---|---|
| `results/metrics/axis_comparison.csv` | Annual direct-beam proxy for fixed, azimuth, horizontal N-S, and dual-axis cases |
| `results/figures/axis_comparison.png` | Bar chart of the same comparison |

---

## 16. Entry and Exit Criteria

### Entry criteria

- The model compiles.
- The parameters are loaded by `setup_project.m` from `project_config.m`.
- The synthetic test inputs are generated by the test scripts.
- The required products are installed.

### Exit criteria

- All planned tests are executed.
- Every failure has a documented resolution or accepted limitation.
- The traceability matrix is complete.
- Results are stored and reproducible.

---

## 17. Current Status

| Area | Status |
|---|---|
| Solar position and geometry unit tests | 10/10 pass |
| Target-angle unit tests | 5/5 pass |
| Axis-comparison unit tests | 4/4 pass |
| Actuator sizing unit tests | 5/5 pass |
| Energy model unit tests | 11/11 pass |
| Mode and deadband unit tests | 15/15 pass |
| Total unit suite | 50/50 pass |
| Axis comparison metrics and figure | Generated |
| Daily energy comparison metrics and figure | Generated |
| Gate G2 design calculations | Complete (preliminary) |
| Baseline Simulink model | Implemented; runs end-to-end |
| Tracking metrics and figure | Generated by `run_project` |
| Simscape plant and actuator model | Implemented; 4/4 closed-form checks pass (T1–T4) |
| Closed-loop plant validation | Implemented; 14/14 checks pass |
| Model, integration, and scenario tests | Implemented in `tests/run_all_tests.m` |

---

<p align="center">
  <i>If it was not tested, it is not done.</i>
</p>
