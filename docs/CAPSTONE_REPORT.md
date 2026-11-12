# Capstone Report — Solar Tracker Control Simulation

> **Status:** Technical content complete for the implemented scope. Remaining
> work is the video and final formatting.
>
> **Rule:** every number in the final report must be traceable to a committed
> script, CSV, or figure in this repository. Do not paste values from memory.

---

## Front Matter

| Field | Content |
|---|---|
| Title | Solar Tracker Control Simulation: Dual-Axis Azimuth–Elevation Control with Actuator Energy Accounting |
| Author | Jhons Janner Samuel S. |
| Programme | MathWorks Excellence in Innovation — Capstone Project 249 |
| Institution | *to be filled* |
| Supervisor | *to be filled* |
| Date | March 2027 |

### Abstract

A photovoltaic panel captures the most energy when its surface faces the sun.
This project designs, models, and simulates a dual-axis azimuth–elevation solar
tracker in MATLAB and Simulink, and asks whether the extra energy it captures
survives the energy the tracker spends on its own motors.

The work has four parts. A NOAA/Meeus solar-position model computes the sun
vector for Malang, Indonesia, and converts it into azimuth and panel-tilt
commands. A clear-sky irradiance model with an isotropic diffuse term and
ground albedo converts panel orientation into captured PV energy. Two explicit
DC-motor and worm-gear axis plants are built from Simscape primitives, so every
electrical and mechanical equation is visible, and two PID loops with a
filtered derivative, clamped integrator, and rate limiter close around them. A
quasi-static motor model then subtracts actuator energy from captured energy.

On the equinox, dual-axis tracking captures 2.449 kWh against 1.836 kWh for a
fixed panel at its optimum tilt, a +33.4 % gain. The tracker spends 0.036 kWh
on its motors, so the net gain is +31.4 %. The closed loops settle in 7.4 s and
7.2 s with 8.1 % and 6.8 % overshoot, steady-state error below 0.02°, and
tracking RMSE below 0.011°. The main limitation is that irradiance is
clear-sky only and the daily energy study uses a reduced-order model; the
physical motor model is validated over short horizons instead.

---

## 1. Introduction

### 1.1 Background
- Why PV orientation matters for captured irradiance.
- Why tracking is a control problem, not only a mechanical one.

### 1.2 Problem Statement
- The panel must follow the sun on two axes while the actuators consume energy.
- The engineering question: does tracking produce a **net** gain after actuator
  consumption?

### 1.3 Objectives
- Mirror the objectives in [README](../README.md#-objectives).
- Each objective must map to a result in Chapter 6.

### 1.4 Scope and Limitations
- Simulation only; no physical hardware.
- Dual-axis baseline; third axis and storage out of scope.
- Cite [System Design §2](SYSTEM_DESIGN.md#2-scope).

---

## 2. Literature Review

### 2.1 Solar Tracking Configurations
- Fixed, single-axis (azimuth, horizontal N–S), dual-axis.
- Cite [References](REFERENCES.md).

### 2.2 Solar Position and Irradiance Models
- NOAA/Meeus, NREL SPA.
- Meinel clear-sky DNI, isotropic diffuse, ground albedo.
- Justify why a clear-sky model is acceptable and what it omits.

### 2.3 Control of Solar Trackers
- PI/PID tracking loops, deadband, night stow.
- Why two independent loops are adequate for this plant.

### 2.4 Research Gap
- Tracking studies often report captured energy without subtracting actuator
  energy. This project reports the net value.

---

## 3. System Design

### 3.1 Requirements
- Summarise [System Design §4–5](SYSTEM_DESIGN.md#4-functional-requirements).
- Reference the [Requirements Checklist](REQUIREMENTS_CHECKLIST.md) for what is
  official and what is a project decision.

### 3.2 Architecture
- Insert the architecture diagram from [System Design §6](SYSTEM_DESIGN.md#6-system-architecture).
- Explain the two closed loops and the feed-forward solar trajectory.

### 3.3 Mechanical Design
- Panel geometry, mass, inertia.
- Gear ratios and the worm-gear constraint.

### 3.4 Actuator Sizing
- Reproduce the Gate G2 table from
  [G2 Design Calculations](design/G2_DESIGN_CALCULATIONS.md).
- State clearly that the values are static sizing confirmed later by the
  dynamic model.

### 3.5 Control Design

The tracker has two independent loops, one per axis, because the mechanical
coupling between azimuth and elevation is weak at tracking speeds. Each loop is
a PID running at a 10 ms sample time in the validation model.

| Term | Implementation | Reason |
|---|---|---|
| Proportional | `Kp` on the angle error | Sets the loop bandwidth |
| Integral | `Ki` with the integrator clamped to ±24 V | Removes steady-state error without wind-up during saturation |
| Derivative | `Kd·wf·s/(s + wf)` on the **measurement** | Adds damping without a kick when the target steps |
| Rate limit | 2400 V/s | The drive can swing the full rail within one control step |
| Saturation | ±24 V | Supply rail |

Two gain sets exist because the reduced-order model and the Simscape plant have
very different voltage-to-angle gains:

| Model | `Kp` | `Ki` | `Kd` | Filter `wf` | Step (s) | Purpose |
|---|---:|---:|---:|---:|---|---|
| Reduced order | 1.0 | 0.1 | — | — | 1.0 s | 24 h energy study |
| Simscape plant | 1.2 | 0.3 | 0.2 | 20 rad/s | 0.01 s | Control and actuator validation |

Two features of the tuning are worth recording because both were found by
simulation rather than by inspection. First, the derivative filter must be
written as `Kd·wf·s/(s + wf)`. With a numerator of `Kd` alone the effective
derivative gain is attenuated by `wf`, which hid a factor-of-20 error and
produced 74–124 % overshoot. Second, the voltage rate limiter dominated the
transient: at 48 V/s it delayed braking by about half a second on a 30° step.
Raising it to 2400 V/s reduced azimuth overshoot from 36 % to 8.1 %.

The elevation loop also rejects a gravity torque `m·g·L·cos(tilt)` that is
largest when the panel is horizontal, and the azimuth loop rejects a constant
wind torque.

### 3.6 Angle Conventions
- Azimuth clockwise from north; tilt from horizontal; target tilt =
  `90° − sun elevation`.

---

## 4. Implementation

### 4.1 Repository Structure
- Reference the tree in [README](../README.md#-repository-structure).
- State the single entry point and why it exists.

### 4.2 MATLAB Modules
| Module | File | Responsibility |
|---|---|---|
| Solar position | `src/sun_position/solar_position.m` | NOAA/Meeus azimuth and elevation |
| Target angles | `src/sun_position/target_angles.m` | Panel tilt and clamping |
| Mode logic | `src/controllers/tracker_mode_logic.m` | Day, deadband, night, cloud, fault |
| Irradiance | `src/energy/clear_sky_irradiance.m` | DNI, DHI, GHI |
| Plane of array | `src/energy/plane_of_array_irradiance.m` | POA from angle of incidence |
| Energy metrics | `src/energy/energy_metrics.m` | Captured, consumed, net |
| Sizing | `src/analysis/design_sizing.m` | Torque, current, speed margins |
| Axis comparison | `src/analysis/compare_tracker_axes.m` | Fixed vs single vs dual |

### 4.3 Simulink and Simscape Model

Two models are used, both generated from scripts so the block diagram is
reproducible from source control.

**`models/solar_tracker.slx` — reduced-order baseline.** A 1 s fixed-step model
with PI loops and gain-plus-integrator axis plants. It runs a full day in about
8 s and produces the tracking metrics used for the daily energy comparison.

**`models/solar_tracker_plant.slx` — explicit plant.** Two axes built from
Simscape Electrical and Mechanical primitives. Each axis contains:

- A controlled voltage source with a current window
  `V = Ke·ω ± Ra·i_limit`, followed by a bus clamp at ±24 V.
- A series `Ra`–`La` armature, a back-EMF term, and a rotational
  electromechanical converter.
- An inertia, viscous friction, and Coulomb friction at the motor.
- A gear that reflects load inertia as `J_load/N²` and divides the disturbance
  torque by `η·N`.
- A measured angle in degrees for the controller and a measured current and
  voltage for the energy and actuator checks.

The elevation axis carries `m·g·L·cos(tilt)`; the azimuth axis carries a
constant 2 N·m wind torque. Both Simscape networks use local solvers at the
10 ms control rate, which is what allows a fixed-step parent model to host
them. Two algebraic loops had to be broken with one-sample delays: the back-EMF
feedback crosses a solver boundary, and the plant output feeds back to the
controller. At 10 ms the delay is negligible for a tracker.

`models/build_axis_plant.m` builds one axis and is shared by the validation
model and the open-loop verification harness, so the plant equations are
defined once.

### 4.4 Entry Point
- `run_project.m` flow: path setup → parameters → trajectory → simulation →
  metrics → figure.

---

## 5. Verification and Testing

### 5.1 Test Strategy
- Levels: unit, model, integration, scenario, regression.
- Reference [Test Plan](TEST_PLAN.md).

### 5.2 Unit Tests

The suite has 50 tests in six files. Command:

```matlab
addpath('tests');
results = run_unit_tests();
assertSuccess(results);
```

| File | Tests | Scope |
|---|---:|---|
| `test_solar_position.m` | 10 | Solar position, sun vector, panel normal, incidence |
| `test_target_angles.m` | 5 | Tilt conversion, clamping, night stow |
| `test_axis_comparison.m` | 4 | Fixed, single-axis, and dual-axis proxy ordering |
| `test_design_sizing.m` | 5 | Torque, current, voltage, speed margins |
| `test_energy_model.m` | 11 | Irradiance, POA, integration, daily net energy, holding current |
| `test_mode_logic.m` | 15 | Day, deadband, night, cloud, fault priority |

Result: 50 passed, 0 failed, 0 incomplete.

### 5.3 Model and Integration Tests

`models/verify_axis_plant.m` checks one axis against closed-form results:

| Check | Reference | Result |
|---|---|---:|
| No-load steady-state speed at 24 V | 458.015 rad/s | 457.955 rad/s (0.01 %) |
| Armature current ceiling | 5 A | 5.000 A |
| Speed rise time | 0.371 s | 0.371 s (0.1 %) |
| Bus ceiling, 30 V command through 24 V bus | 24 V | 24.000 V |

`models/validate_tracker_plant.m` closes the loops and runs a 30° / 45° step
plus a two-hour tracking window. All 14 checks pass; the results are in
Chapter 6.

`tests/run_all_tests.m` runs environment, unit, axis plant, plant validation,
integration, and sizing as six stages and writes
`results/test-reports/test_summary.csv`. It also simulates the baseline twice
and compares the outputs for reproducibility. On 2026-11-11: 6 stages passed,
0 failed, 0 skipped.

### 5.4 Scenario Tests
- Clear, cloudy, rainy, sunrise, sunset, night.

### 5.5 Reproducibility
- Clean-clone run and regenerated outputs.

---

## 6. Results and Discussion

### 6.1 Solar Tracking Response

The baseline model follows the full 24 h solar trajectory at 1 s resolution.
Azimuth RMSE is 0.1866° and tilt RMSE is 0.0778°. The maximum errors, 3.94° and
1.32°, occur at sunrise and sunset, where the target azimuth sweeps fastest and
the deadband hands over between hold and track.

**Source:** `results/metrics/tracking_metrics.csv`,
`results/figures/tracking_response.png`

### 6.2 Controller Performance

On the Simscape plant the loops meet every step criterion:

| Metric | Azimuth | Tilt | Criterion |
|---|---:|---:|---|
| Rise time 10–90 % | 0.48 s | 0.57 s | ≤ 10 s |
| Overshoot | 8.07 % | 6.84 % | ≤ 10 % |
| Settling time (2 %) | 7.43 s | 7.18 s | ≤ 20 s |
| Steady-state error | 0.011° | 0.007° | ≤ 0.2° |
| Peak armature current | 5.000 A | 5.000 A | ≤ 5.1 A |

The peak current sits exactly at the 5 A driver limit on both axes, which
confirms that the current window is active during the move and that the
controller is not asking for torque the drive cannot deliver.

Tracking on the same plant gives 0.0108° azimuth RMSE and 0.0099° tilt RMSE,
with maxima of 0.347° and 0.310°. These are two orders of magnitude below the
reduced-order baseline errors, because the plant model runs at 10 ms instead of
1 s and does not include the deadband and stow transitions of the daily model.

### 6.3 Energy Performance

Daily energy on 2026-03-21, 5-minute sampling, 1.6 m² panel, 18 % efficiency,
0.85 system loss factor:

| Configuration | PV (kWh) | Actuator (kWh) | Net (kWh) | PV gain | Net gain |
|---|---:|---:|---:|---:|---:|
| Fixed, tilt 8° | 1.836 | 0 | 1.836 | — | — |
| Single-axis azimuth, tilt 43° | 2.299 | 0.009 | 2.289 | +25.2 % | +24.7 % |
| Dual-axis | 2.449 | 0.036 | 2.413 | +33.4 % | +31.4 % |

The actuator term is estimated from a quasi-static torque balance using the
same motor and gear parameters as the Simscape plant. The dual-axis tracker
spends 36 Wh/day, most of it holding the panel against gravity at night on the
conservative assumption of a non-self-locking worm gear. The net gain remains
+31.4 %, so the tracker is worth its own energy on this day.

Seasonally, the dual-axis net gain is +37.9 % on 2026-06-21 and +44.9 % on
2026-12-21. The annual direct-beam proxy gives a higher +43.4 %, because it
ignores diffuse light and ground reflection.

**Source:** `results/metrics/daily_energy_comparison.csv`,
`results/metrics/axis_comparison.csv`

### 6.4 Operating Scenarios
- Behaviour under cloud, rain, and night.
- Deadband and stow behaviour.

### 6.5 Fault Response
- Detection, safe state, recovery.

### 6.6 Discussion
- Where the design meets the objectives.
- Where it does not, and why.
- Sensitivity to site, date, and parameter choices.

---

## 7. Generative AI Disclosure

> This section is mandatory. It must match
> [AI Usage Log §4](AI_USAGE_LOG.md#4-disclosure-statement) word for word.

Include:
- Tool and model used.
- What AI was used for.
- What AI was **not** used for.
- How each output was verified.
- A statement that the author can reproduce the work.

---

## 8. Conclusion and Future Work

### 8.1 Conclusion

The project set out to build a dual-axis tracker in simulation and to answer
whether tracking is worth its own actuator energy. It is: on the equinox the
dual-axis tracker captures 2.449 kWh against 1.836 kWh for a fixed panel and
spends 0.036 kWh moving and holding itself, for a net gain of +31.4 %. The
single-axis azimuth case captures less but also spends less, at +24.7 % net.

The control loops meet every stated criterion on the explicit motor and gear
plant: 8.07 % and 6.84 % overshoot, 7.43 s and 7.18 s settling, steady-state
error below 0.02°, and tracking RMSE below 0.011°. The plant itself matches
closed-form theory to better than 0.2 % on steady-state speed and rise time, and
the current and voltage ceilings hold exactly.

The main limitations are the clear-sky irradiance model, the reduced-order
daily model, and the quasi-static actuator energy estimate. None of them
changes the direction of the result, but each would tighten the numbers.

### 8.2 Future Work

- Third (roll/polar) axis, only if it earns its actuator energy.
- MPC or fuzzy control compared against the PID baseline in the same scenarios.
- Measured irradiance and cloud data instead of the clear-sky model.
- Hardware-in-the-loop and a physical prototype.
- Battery storage and MPPT, which change the value of the captured energy.

---

## References

Use the [References](REFERENCES.md) list. Number them in citation order and
keep one style throughout. Every citation must be real and checkable.

---

## Appendix A — Repository Map

Link to the tree in [README](../README.md#-repository-structure).

## Appendix B — Parameter Table

Reproduce the parameter groups from `src/initialization/project_config.m`:
site, simulation, tracker, controller, actuator, energy, weather, analysis.

## Appendix C — Test Results

Paste the output of:

```matlab
addpath('tests');
results = run_unit_tests();
table(results)
```

Expected: 50 passed, 0 failed.

## Appendix D — Reproduction Steps

```matlab
git clone https://github.com/JhonsJSSimatupang/Solar-Tracker-Control-Simulation.git
cd Solar-Tracker-Control-Simulation
run_project
addpath('tests');
summary = run_all_tests();
disp(summary)
```

The runner returns a summary table with one row per stage and throws
`run_all_tests:Failed` when any stage fails, so a CI job can rely on the exit
status.

---

## Writing Checklist

- [ ] Every figure has a caption and a source file.
- [ ] Every table has units.
- [ ] Every requirement in Chapter 3 appears in Chapter 6.
- [ ] Every number matches a committed CSV.
- [ ] GenAI disclosure matches the log.
- [ ] References are real and consistently formatted.
- [ ] No AI-sounding filler; short sentences, concrete claims.
- [ ] Page count and formatting follow the institution template.

---

_Last updated: 2026-11-11_
