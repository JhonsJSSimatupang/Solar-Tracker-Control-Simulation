# 🧪 Test Plan

## Solar Tracker Control Simulation

> **Status:** Unit tests implemented and passing (24/24 on 2026-11-09).
> Model, integration, scenario, and regression tests are pending installation of
> the Simscape and Control System Toolbox products.

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

| Item | Value |
|---|---|
| MATLAB version | R2026a Update 4 (26.1.0.3312084) |
| Simulink version | R2026a (26.1) |
| Installed products | MATLAB, Simulink, Stateflow, Fuzzy Logic Toolbox, MATLAB MCP Server Toolbox |
| Required but not yet installed | Simscape, Simscape Multibody, Simscape Electrical, Control System Toolbox, Simulink Control Design |
| Optional toolboxes | App Designer, Statistics and Machine Learning Toolbox |
| Operating system | Windows 11 Home Single Language (build 26200) |
| Reference data | NOAA Solar Calculator, NREL SPA, NASA POWER, BMKG |

All tests must run from the repository root using `run_project.m` or a
documented test script.

---

## 3. Test Levels

| Level | Purpose | Location | Status |
|---|---|---|---|
| Static | Detect code and model quality issues | Code Analyzer, Model Advisor | Code Analyzer available; Model Advisor pending |
| Unit | Verify individual functions | `tests/unit/` | Implemented, 24/24 passing |
| Model | Verify controllers, actuators, and mechanics | `tests/model/` | Pending toolboxes |
| Integration | Verify the full tracking chain | `tests/integration/` | Pending model |
| Scenario | Verify behavior under operating conditions | `tests/scenarios/` | Pending model |
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

A small sample dataset must be stored in `data/sample/` so the tests can run
without an internet connection.

---

## 5. Static Tests

| ID | Test | Tool | Pass criterion | Status |
|---|---|---|---|---|
| ST-01 | Code Analyzer on all `.m` files | `checkcode` | No errors; warnings reviewed | Open |
| ST-02 | Model Advisor on the main model | Model Advisor | No unresolved errors | Pending model |
| ST-03 | No hard-coded absolute paths | Manual review | All paths relative or derived from `projectRoot` | Open |
| ST-04 | No generated files committed | Git review | `slprj/`, `*.slxc`, autosave files absent | Open |

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

### 6.5 Planned unit tests

| ID | Test | Pass criterion |
|---|---|---|
| UT-ENERGY-05 | Plane-of-array irradiance | Matches hand calculation within 1% |
| UT-ENERGY-06 | Daily energy integration | Matches numerical integration within 1% |
| UT-STRAT-01 | Deadband logic | No command inside the deadband; command outside the deadband |
| UT-STRAT-02 | Mode transitions | No chattering; transitions documented |
| UT-STRAT-03 | Night stow with hysteresis | Tracker enters and leaves stow without chattering |

### 6.6 Execution evidence

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
Running test_solar_position
..........
Running test_target_angles
.....

Passed: 24, Failed: 0, Incomplete: 0
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
| FR-03 | Mode logic (Stateflow / MATLAB Function) | UT-STRAT-01…03 | TBD | Open |
| FR-04 | Azimuth PID | MT-CTRL-01…03 | TBD | Open |
| FR-05 | Elevation PID | MT-CTRL-04…06 | TBD | Open |
| FR-06 | Integrated tracking chain | IT-02, IT-05 | TBD | Open |
| FR-07 | Actuator models | MT-ACT-01…04 | TBD | Open |
| FR-08 | Two-axis mechanical model | MT-MECH-01…04 | TBD | Open |
| G2 sizing | `src/analysis/design_sizing.m` | UT-SIZE-01…05 | 5/5 pass | Verified (unit) |
| FR-09 | Irradiance model | UT-ENERGY-05 | TBD | Open |
| FR-10 | Energy accounting | UT-ENERGY-06, IT-04 | TBD | Open |
| FR-11 | Scenario set | SC-01…07 | TBD | Open |
| FR-12 | Fault detection and safe state | SC-07 | TBD | Open |
| FR-13 | `run_project.m` | RP-01…04 | TBD | Open |
| NFR-01 | `run_project.m` | RP-01 | TBD | Open |
| NFR-02 | README and dependencies | RP-02 | TBD | Open |
| NFR-03 | `project_config.m`, `setup_project.m` | ST-03 | TBD | Open |
| NFR-04 | Documentation and results | RP-03 | TBD | Open |
| NFR-05 | Runtime budget | RP-04 | TBD | Open |
| NFR-06 | Code Analyzer / Model Advisor | ST-01, ST-02 | TBD | Open |
| NFR-07 | Documentation set | Manual review | TBD | Open |
| NFR-08 | AI usage log | Manual review | TBD | Open |
| NFR-09 | Offline sample data | RP-02 | TBD | Open |
| NFR-10 | LICENSE | Manual review | TBD | Open |

---

## 14. Defect Log

| ID | Date | Test case | Description | Severity | Status | Resolution |
|---|---|---|---|---|---|---|
| DEF-001 | 2026-11-09 | UT-SPA-01 | Equation-of-time formula returned radians but was treated as degrees; azimuth error about 4.6°. | High | Closed | Wrapped the equation-of-time expression in `rad2deg`; golden case now passes. |
| DEF-002 | 2026-11-09 | UT-COORD-02 | `panel_normal` defined tilt 0° as facing north instead of facing up. | High | Closed | Redefined the normal as `[sin(tilt)·sin(az); sin(tilt)·cos(az); cos(tilt)]`. |
| DEF-003 | 2026-11-09 | All unit tests | Test methods used `self.` instead of `testCase.`, so the properties were undefined. | Medium | Closed | Replaced `self.` with `testCase.`. |
| DEF-004 | 2026-11-09 | UT-ENERGY-01 | `solar_vector` and `panel_normal` did not expand a scalar angle against a vector. | Medium | Closed | Added scalar-expansion handling and a size-mismatch error. |

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
- The test data are available in `data/`.
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
| Total unit suite | 24/24 pass |
| Axis comparison metrics and figure | Generated |
| Gate G2 design calculations | Complete (preliminary) |
| Simulink model | Not started; blocked by missing products |
| Model, integration, and scenario tests | Pending model |

---

<p align="center">
  <i>If it was not tested, it is not done.</i>
</p>
