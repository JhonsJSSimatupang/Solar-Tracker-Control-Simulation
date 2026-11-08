# 🧩 System Design

## Solar Tracker Control Simulation

> **Status:** Requirements baseline (Gate G1) — dual-axis configuration selected,
> pending formal team sign-off.
>
> **Scope:** simulation only. No physical hardware is required.

This document defines the system requirements, architecture, interfaces, and
design decisions for the solar tracker control simulation.

---

## 1. Purpose

The system simulates a dual-axis solar tracker that rotates a photovoltaic (PV)
panel about a vertical azimuth axis and a horizontal elevation (tilt) axis to
follow the sun's apparent path. The objective is to increase the irradiance
received by the panel compared with a fixed installation.

The project is a control-engineering study. The main question is not only
"can the panel follow the sun?" but also "does two-axis tracking produce a net
energy gain after the actuator consumption of both axes is subtracted?"

---

## 2. Scope

### In scope

- A dual-axis azimuth–elevation tracker.
- A solar position algorithm for any date, time, and site.
- A target-angle generator for both axes with deadband and night-stow logic.
- Two PID controllers, one for azimuth and one for panel tilt.
- Two DC gear-motor models in Simscape Electrical.
- A two-axis mechanical tracker model in Simscape Multibody.
- A clear-sky irradiance and energy model.
- A comparison of fixed, single-axis azimuth, horizontal north–south, and
  dual-axis configurations.
- Scenario simulations for clear, cloudy, rainy, sunrise, sunset, and night.
- Unit, integration, scenario, and regression tests.

### Out of scope (unless time permits)

- A third (roll/polar) axis.
- MPPT, battery storage, and grid connection.
- Machine-learning sun prediction.
- Physical hardware, PCB design, and manufacturing actuator sizing.

The dual-axis baseline directly addresses the multi-axis project brief. A
single-axis azimuth case is retained in the energy analysis for comparison and
as a candidate degraded mode; it is not the main simulation model.

---

## 3. Assumptions and Constraints

| ID | Assumption or constraint |
|---|---|
| A-01 | The installation site is Malang, East Java, Indonesia: latitude -7.9666°, longitude 112.6326°, UTC+7. |
| A-02 | The panel is mounted on a two-axis gimbal: azimuth (yaw) about a vertical axis and elevation (tilt) about a horizontal axis. There is no fixed panel tilt. |
| A-03 | The azimuth axis has a mechanical range of at least 0° to 360°. |
| A-04 | The elevation axis sets the panel tilt from horizontal. The preliminary range is 0° to 85°; the upper limit avoids the gimbal singularity at zenith and reduces wind load. |
| A-05 | Each axis is driven by a brushed DC gear motor supplied by an H-bridge driver. |
| A-06 | The controller runs at a fixed sample time of 0.01 s. The energy calculation uses a 1 s sample time. Full-day runs may use a 0.1 s solver step, to be confirmed at Gate G3. |
| A-07 | Weather data are represented by a clear-sky model and optional NASA POWER or BMKG samples. |
| A-08 | The model must run on MATLAB R2026a with the products listed in `docs/SETUP.md`. |
| A-09 | All parameters are defined in `src/initialization/project_config.m` and loaded by `setup_project.m`; no model block contains a hard-coded design parameter. |
| A-10 | The elevation axis carries the panel and frame; the gravity torque on the elevation axis is included in the mechanical model. |

Angle conventions:

- Azimuth is measured clockwise from north, 0° to 360°.
- Panel tilt is measured from the horizontal plane: 0° = horizontal,
  90° = vertical.
- The elevation-axis command is the panel tilt, **not** the solar elevation.
  To face the sun, the target tilt is `90° - sun elevation`.

---

## 4. Functional Requirements

The acceptance criteria are preliminary baseline targets. They are confirmed or
revised at Gate G2 after the motor and mechanical design calculations.

| ID | Requirement | Acceptance criterion | Verification |
|---|---|---|---|
| FR-01 | Compute the solar azimuth and elevation for a given site and time. | Azimuth and geometric elevation within 0.1° of NREL SPA/NOAA reference values. | Unit tests |
| FR-02 | Generate target angles for both axes. | Azimuth target equals the sun azimuth; tilt target equals `90° - sun elevation`; both are clamped to the mechanical limits. Night-stow target is applied when elevation < 0°. | Unit tests and simulation |
| FR-03 | Apply deadband and mode logic. | No actuator command inside the deadband; no chattering at mode boundaries. | Unit tests and simulation |
| FR-04 | Control the azimuth axis. | For a 30° step: settling time ≤ 15 s, overshoot ≤ 10%, steady-state error ≤ 0.2°. | Model test |
| FR-05 | Control the elevation (tilt) axis. | For a 20° step: settling time ≤ 15 s, overshoot ≤ 10%, steady-state error ≤ 0.2°. | Model test |
| FR-06 | Track the moving sun on both axes. | RMS azimuth error ≤ 0.5° and RMS tilt error ≤ 0.5° during a clear day. | Integration test |
| FR-07 | Model both actuators. | Motor speed and torque follow the motor equations; voltage and current are limited. | Model test |
| FR-08 | Model the two-axis mechanical tracker. | Axes move in the correct direction, respect limits, and have no singularities in the 0°–85° tilt range. | Model test and Model Advisor |
| FR-09 | Compute the irradiance on the panel. | Angle of incidence and plane-of-array irradiance match hand calculations within 1%. | Unit test |
| FR-10 | Compute captured and consumed energy. | Daily energy values match numerical integration within 1%; actuator energy from both axes is included. | Unit test and simulation |
| FR-11 | Run the defined operating scenarios. | Clear, cloudy, rainy, sunrise, sunset, and night scenarios complete without solver errors. | Scenario tests |
| FR-12 | Detect and respond to a fault. | A motor or sensor fault is detected and the tracker enters a safe state. | Scenario test |
| FR-13 | Produce a reproducible result set. | `run_project.m` regenerates the figures and metrics from a clean clone. | Reproducibility test |

### Advanced requirements (stretch)

| ID | Requirement | Acceptance criterion |
|---|---|---|
| FR-A1 | Add a third (roll/polar) axis. | Third-axis tracking error ≤ 0.5° RMS; energy gain reported against the dual-axis case. |
| FR-A2 | Compare PID with an advanced controller. | Same scenarios; performance and control effort compared in a table. |
| FR-A3 | Provide an interactive dashboard. | User can change date, site, weather, and controller gains and see the response. |

---

## 5. Non-Functional Requirements

| ID | Requirement | Acceptance criterion |
|---|---|---|
| NFR-01 | Single entry point. | `run_project.m` runs the complete analysis without manual steps. |
| NFR-02 | Clean-install reproducibility. | A clean MATLAB installation with the documented products can run the project. |
| NFR-03 | Centralized parameters. | All design parameters are defined in `project_config.m`, loaded by `setup_project.m`, and passed to the model. |
| NFR-04 | Traceability. | Every requirement maps to a design element and a test in `docs/TEST_PLAN.md`. |
| NFR-05 | Runtime. | A 24-hour simulation completes in ≤ 10 minutes on the target laptop at the documented full-day solver step. |
| NFR-06 | Code quality. | Code Analyzer reports no errors; Model Advisor reports no unresolved errors. |
| NFR-07 | Documentation. | README, system design, test plan, and results are complete and consistent. |
| NFR-08 | AI transparency. | Every non-trivial AI-assisted change is recorded in `docs/AI_USAGE_LOG.md`. |
| NFR-09 | Offline sample data. | The test suite runs without an internet connection using `data/sample/`. |
| NFR-10 | License. | The repository uses an open-source license (BSD-2-Clause or MIT). |

---

## 6. System Architecture

```mermaid
flowchart TD
    A[Site, date, time] --> B[Solar Position]
    B --> C[Target and Mode Logic]
    C --> D1[Azimuth PID]
    C --> D2[Elevation / Tilt PID]
    D1 --> E1[Azimuth Motor and Driver]
    D2 --> E2[Elevation Motor and Driver]
    E1 --> F1[Azimuth Joint]
    E2 --> F2[Elevation Joint]
    F1 --> G[Panel Orientation]
    F2 --> G
    G --> H[Irradiance Model]
    H --> I[Energy Accounting]
    I --> J[Figures and Metrics]
    C --> K[Operating Mode / Stateflow]
    K --> D1
    K --> D2
    F1 --> D1
    F2 --> D2
```

The two controllers and the two plant axes form two closed loops. The solar
position and the irradiance model are feed-forward inputs; they do not depend
on the panel orientation, except through the angle of incidence.

The azimuth and elevation loops are mechanically coupled through the panel, but
the coupling is weak at the tracking speeds of interest. Each axis is therefore
controlled by its own PID loop, with the coupling verified in the integrated
simulation.

---

## 7. Subsystems

### 7.1 Solar Position

- **Inputs:** site latitude, longitude, UTC offset, date, time.
- **Outputs:** solar azimuth, geometric elevation, zenith, declination, hour
  angle, equation of time.
- **Algorithm:** NOAA/Meeus equations, implemented in
  `src/sun_position/solar_position.m`.
- **Validation:** NREL SPA reference case and physical invariants (east in the
  morning, west in the afternoon, equinox noon elevation).
- **Accuracy:** the implementation matches the NREL SPA geometric elevation to
  better than 0.01° and the azimuth to better than 0.01° for the reference
  case.

### 7.2 Target and Mode Logic

The target generator converts the sun position into commands for both axes.

| Mode | Condition | Target / action |
|---|---|---|
| `DAY_TRACK` | Sun elevation > 0° and either axis error > deadband | Azimuth target = sun azimuth; tilt target = `90° - sun elevation`; both clamped to limits |
| `DEADBAND_HOLD` | Sun elevation > 0° and both errors ≤ deadband | Hold the last target on each axis |
| `NIGHT_STOW` | Sun elevation ≤ 0° | Move to the stow position and stop |
| `CLOUD_HOLD` | Cloud cover above threshold | Hold position to save actuator energy |
| `FAULT_SAFE` | Fault detected | Disable both motors and hold the axes |

The mode logic will be implemented in Stateflow or a MATLAB Function block. The
deadband is a configurable parameter per axis (preliminary value: 0.5°).

The tilt conversion is explicit in the implementation:

```matlab
targetAzimuth = sun.azimuth;
targetTilt    = 90 - sun.elevation;
```

A night-stow position of azimuth 0° (north) and tilt 0° (horizontal) is used as
the preliminary value. The final stow position is confirmed at Gate G2.

### 7.3 Controllers

- Baseline: two PID controllers with anti-windup, output saturation, and a rate
  limiter.
- Inputs: azimuth error and tilt error (target minus measured).
- Outputs: motor voltage or current commands.
- Design method: root locus / frequency response using Control System Toolbox,
  followed by simulation tuning.
- The azimuth loop rejects wind and bearing disturbances. The elevation loop
  additionally rejects the gravity torque of the panel, which varies with tilt.
- Advanced option: gain-scheduled PID or fuzzy logic, compared against the PID
  baseline in the same scenarios.

### 7.4 Actuators and Motors

Two brushed DC gear motors are used for the baseline. Each model includes:

- Armature resistance and inductance.
- Torque constant and back-EMF constant.
- Gear ratio and gear efficiency.
- Static and viscous friction.
- Voltage and current limits.
- Motor shaft inertia reflected to the output.

The azimuth stage uses a worm gear, following the Simscape example. The
elevation stage uses a worm gear or a geared motor with a holding brake; the
final choice is made at Gate G2. The motor and gear parameters are selected
from a torque calculation that includes panel inertia, gravity torque, bearing
friction, and wind disturbance.

### 7.5 Mechanical Tracker

- Based on the Simscape Multibody example *Using the Worm and Gear Constraint
  Block – Solar Tracker* for the azimuth stage.
- One revolute joint for the azimuth axis (vertical).
- One revolute joint for the elevation axis (horizontal).
- A worm gear prevents back-driving on the azimuth axis when the motor is
  unpowered. The elevation axis uses a worm gear or a brake for the same
  purpose.
- Panel dimensions, mass, center of mass, and inertia are parameters.
- Joint limits, damping, and friction are documented.
- The tilt range is limited to 0°–85° to avoid the gimbal singularity at
  zenith, where the azimuth is undefined.

### 7.6 Irradiance and Energy

The energy model is implemented in `src/energy/` and computes:

- Solar incidence angle from the sun vector and the panel normal.
- Direct normal irradiance (DNI), diffuse horizontal irradiance (DHI), and
  global horizontal irradiance (GHI) with a Meinel clear-sky model.
- Plane-of-array irradiance with the isotropic sky model.
- Instantaneous PV power with a linear efficiency model, then daily energy.
- Actuator electrical energy for both axes from voltage and current.
- Net energy = captured PV energy − actuator energy.

| Module | Function |
|---|---|
| `clear_sky_irradiance.m` | DNI, DHI, and GHI from the solar elevation |
| `plane_of_array_irradiance.m` | Isotropic POA irradiance on a tilted panel |
| `energy_metrics.m` | PV and actuator energy integration |
| `daily_energy_simulation.m` | Full-day PV energy for one configuration |
| `compare_daily_energy.m` | Fixed, azimuth, and dual-axis daily comparison |

The clear-sky model uses the Meinel direct-beam expression
`DNI = 1.353 × 0.7^(AM^0.678)` with `AM = 1/sin(elevation)`, a constant diffuse
fraction `DHI = 0.10 × DNI`, and a ground albedo of 0.20. The model is a
screening model; measured NASA POWER or BMKG data can replace it in the
scenario tests.

The analysis script `src/analysis/compare_tracker_axes.m` compares four cases
with the direct-beam proxy:

1. Fixed panel at the optimal tilt.
2. Single-axis azimuth tracker at the optimal fixed tilt.
3. Horizontal north–south single-axis tracker.
4. Ideal dual-axis tracker (panel normal follows the sun).

The first-pass direct-beam proxy for Malang 2026 gives +43.4% for the ideal
dual-axis case relative to the fixed optimum. The daily model, which includes
diffuse and ground-reflected irradiance, gives +33.4% on 2026-03-21, +40.1% on
2026-06-21, and +47.0% on 2026-12-21. The daily model is the more realistic
estimate; the annual proxy is retained as a fast screening tool.

The actuator energy is not yet included in the daily simulation because the
motor and controller model does not exist. `energy_metrics` accepts the
actuator power from the Simulink model, so the net energy will be available
when the model is built.

---

## 8. Interfaces

| Interface | From | To | Signal / Data | Unit |
|---|---|---|---|---|
| I-01 | Solar position | Target logic | Sun azimuth | deg |
| I-02 | Solar position | Target logic | Sun elevation | deg |
| I-03 | Target logic | Azimuth controller | Target azimuth | deg |
| I-04 | Target logic | Elevation controller | Target panel tilt | deg |
| I-05 | Mechanical tracker | Azimuth controller | Measured azimuth | deg |
| I-06 | Mechanical tracker | Elevation controller | Measured panel tilt | deg |
| I-07 | Azimuth controller | Azimuth driver | Voltage command | V |
| I-08 | Elevation controller | Elevation driver | Voltage command | V |
| I-09 | Azimuth motor | Azimuth joint | Torque | N·m |
| I-10 | Elevation motor | Elevation joint | Torque | N·m |
| I-11 | Mechanical tracker | Energy model | Panel azimuth | deg |
| I-12 | Mechanical tracker | Energy model | Panel tilt | deg |
| I-13 | Solar position | Energy model | Sun vector | — |
| I-14 | Energy model | Results | PV energy, actuator energy | Wh |

Sign conventions:

- Azimuth is clockwise from north, 0° to 360°.
- Panel tilt is measured from horizontal, 0° to 85°.
- Positive azimuth torque rotates the panel clockwise when viewed from above.
- Positive elevation torque increases the panel tilt (raises the panel toward
  vertical).
- Positive azimuth error means the panel must rotate clockwise.
- Positive tilt error means the panel must be raised toward vertical.

---

## 9. Design Decisions

| Date | Decision | Rationale | Status |
|---|---|---|---|
| 2026-11-09 | Site: Malang (-7.9666°, 112.6326°, UTC+7). | Home campus location; equatorial site with high solar elevation; data available from NASA POWER and BMKG. | Proposed |
| 2026-11-09 | Baseline axis: dual-axis azimuth–elevation. | Directly addresses the multi-axis project brief; the direct-beam proxy shows the highest energy gain (+43.4%) and both axes are controlled. | Accepted (team decision) |
| 2026-11-09 | Single-axis azimuth retained as an analysis case. | Provides a fair tracking comparison and a candidate degraded mode if the elevation actuator fails. | Accepted |
| 2026-11-09 | Advanced extension: third (roll/polar) axis. | Adds a further tracking degree of freedom only if the dual-axis baseline is completed on schedule. | Optional |
| 2026-11-09 | Solar position: NOAA/Meeus. | Accuracy better than 0.02°, simple implementation, no additional toolbox, validated against NREL SPA. | Accepted |
| 2026-11-09 | Controllers: two PID loops. | Standard, transparent, and supported by Control System Toolbox. An advanced controller is compared only after the PID baseline passes. | Proposed |
| 2026-11-09 | Motors: brushed DC gear motors. | Simple electrical model, suitable for a small panel, and supported by Simscape Electrical. | Proposed |
| 2026-11-09 | Mechanics: worm gear on azimuth, worm gear or brake on elevation. | The Simscape example provides a starting point; the worm gear holds position when unpowered. | Proposed |
| 2026-11-09 | Panel tilt: no fixed tilt; set by the elevation axis. | The second axis removes the fixed-tilt compromise and lets the panel normal follow the sun. | Accepted (consequence of dual-axis) |
| 2026-11-09 | Energy metric: net energy after actuator consumption. | A tracker that captures more irradiance but consumes more actuator energy may not be worth it; the net metric answers the engineering question. | Proposed |
| 2026-11-09 | Preliminary gear ratios: 100:1 azimuth, 150:1 elevation. | The G2 static sizing gives a required output torque of 11.4 N·m and 17.1 N·m. Both ratios keep the motor current below 3.3 A against a 5 A limit and give a torque margin of about 1.54. | Accepted (preliminary) |
| 2026-11-09 | Preliminary motor: 24 V brushed DC, `K_t = 0.05 N·m/A`, `R = 1.2 Ω`. | Representative parameters for the simulation; the final motor is confirmed at Gate G3. | Accepted (preliminary) |
| 2026-11-09 | Elevation holding: worm gear or brake to be decided at G3. | The holding current at tilt 0° is 1.12 A (1.5 W); a self-locking gear or brake can avoid the holding energy. | Open |

---

## 10. Preliminary Parameters

These values are the Gate G2 preliminary design. They are not final; the
dynamic model at Gate G3 confirms them. The full calculation is in
[G2 Design Calculations](design/G2_DESIGN_CALCULATIONS.md).

| Parameter | Preliminary value | Notes |
|---|---|---|
| Panel width × height | 1.0 m × 1.6 m | About 1.6 m² |
| Panel mass | 12 kg | Frame and cells |
| Panel centre-of-mass offset | 0.05 m | Along the panel height |
| Azimuth range | 0° to 360° | Continuous rotation or limited range |
| Elevation (tilt) range | 0° to 85° | Avoids the zenith singularity |
| Stow position | Azimuth 0°, tilt 0° | Horizontal, low wind load |
| Deadband | 0.5° per axis | Reduce actuator wear |
| Azimuth gear ratio | 100:1 | Selected by the G2 torque calculation |
| Elevation gear ratio | 150:1 | Selected by the G2 torque calculation |
| Gear efficiency | 0.70 | Worm-gear estimate |
| Friction torque | 1.0 N·m per axis | Bearing and seal estimate |
| Design acceleration | 0.05 rad/s² | Worst-case sizing |
| Design slew rate | 2°/s | Worst-case sizing |
| Wind torque allowance | 10 N·m per axis | Static worst-case gust |
| Panel inertia about tilt axis | 3.5 kg·m² | Includes frame and hardware |
| Panel inertia about azimuth axis | 8.0 kg·m² | Includes frame and hardware |
| Motor rated voltage | 24 V | Both axes |
| Motor armature resistance | 1.2 Ω | Preliminary motor |
| Motor torque constant | 0.05 N·m/A | Preliminary motor |
| Motor back-EMF constant | 0.05 V·s/rad | Preliminary motor |
| Motor current limit | 5 A | Driver limit |
| Controller sample time | 0.01 s | Preliminary |
| Energy sample time | 1 s | Preliminary |
| Full-day solver step | 0.1 s | Preliminary; controller tests use 0.01 s |
| Simulation duration | 24 h | One full day |
| PV conversion efficiency | 18% | Preliminary linear model |

The sizing results are:

| Quantity | Azimuth | Elevation |
|---|---:|---:|
| Required output torque | 11.40 N·m | 17.06 N·m |
| Motor torque | 0.163 N·m | 0.162 N·m |
| Motor current | 3.26 A | 3.25 A |
| Torque margin | 1.54 | 1.54 |
| Speed margin | 137.5 | 91.7 |

The values are recorded in `src/initialization/project_config.m` and in
`docs/design/G2_DESIGN_CALCULATIONS.md`.

---

## 11. Open Issues

- [x] Confirm the axis baseline: dual-axis azimuth–elevation selected on
  2026-11-09.
- [ ] Obtain formal team sign-off on Gate G1.
- [x] Calculate the panel inertia and the required torque for both axes.
- [x] Select the preliminary motors and gear ratios for both axes.
- [ ] Confirm the motor and gearbox selection with the dynamic model at Gate G3.
- [ ] Define the stow position and the mechanical limits.
- [ ] Select the irradiance model and the weather data source.
- [ ] Validate the tilt and energy estimates with a diffuse sky model.
- [ ] Define the exact PID step-response targets after the plant model exists.
- [ ] Decide whether the third axis is included in the final submission.
- [ ] Install the missing products for Gate G0.

---

## 12. References

See [REFERENCES.md](REFERENCES.md).
