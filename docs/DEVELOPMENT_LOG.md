# 📝 Development Log

## Solar Tracker Control Simulation

---

This document records the activities, decisions, challenges, and progress throughout the development of the Capstone Project.

All entries are organized chronologically to maintain a clear development history.

---

## Development History

### November 7, 2026 — Initial Repository Setup

**Status:** Initial Preparation

#### Activities

- [x] Established the GitHub repository.
- [x] Organized the initial project directory structure.
- [x] Prepared the main README documentation.
- [x] Created the project planning document.
- [x] Created the development log.

#### Progress

The repository has been established as the central workspace for the Solar Tracker Control Simulation Capstone Project.

The initial focus is on creating an organized development environment and preparing the documentation structure before beginning the technical development phase.

#### Current State

- Repository structure: Prepared.
- Project documentation: Initial version completed.
- MATLAB implementation: Not started.
- Simulink modeling: Not started.
- Simulation results: Not available.

#### Next Steps

- Define the project scope.
- Begin literature study.
- Identify system requirements.
- Establish the initial technical direction.

---

### November 9, 2026 — Repository Structure Alignment

**Status:** Completed

#### Activities

- [x] Renamed `simulink/` to `models/` and moved reusable libraries to `models/libraries/`.
- [x] Reorganized `src/` into `initialization/`, `sun_position/`, `controllers/`, and `analysis/`.
- [x] Moved the main entry point to `run_project.m` at the repository root.
- [x] Renamed `results/simulation/` to `results/metrics/`.
- [x] Added `.gitignore` rules for MATLAB and Simulink generated files.
- [x] Added the initial `SYSTEM_DESIGN.md` and `REFERENCES.md` documents.
- [x] Updated the repository structure and run instructions in `README.md`.

#### Progress

The repository now follows the recommended structure for a MathWorks Challenge Project submission: a single entry point, a clear separation between models, source code, data, results, documentation, and tests.

#### Next Steps

- Define the project scope and system requirements.
- Select the installation site and tracker axis configuration.
- Begin the literature study and collect references.

---

### November 9, 2026 — Execution Workflow and Verification Plan

**Status:** Completed

#### Activities

- [x] Added `docs/WORKFLOW.md` with the end-to-end phases and review gates.
- [x] Added `docs/TEST_PLAN.md` with test levels, test cases, and pass criteria.
- [x] Added `docs/AI_USAGE_LOG.md` with the generative AI protocol and log template.
- [x] Updated the README repository tree and documentation table.

#### Progress

The project now has a defined execution flow with gates, a testing strategy aligned with the requirements, and a protocol for using generative AI transparently. The workflow is designed so that the team owns the engineering work and can explain every part of the submission.

#### Next Steps

- Complete the requirements baseline at Gate G1.
- Start the literature study and record references.
- Record the MATLAB version and installed toolboxes at Gate G0.

---

### November 9, 2026 — Environment Audit and Setup Guide

**Status:** Superseded (products installed later the same day)

#### Activities

- [x] Audited the installed MATLAB products.
- [x] Added `tests/check_environment.m`.
- [x] Added `docs/SETUP.md` with installation steps and the Gate G0 checklist.
- [ ] Install the missing toolboxes.
- [ ] Re-run the environment check.

#### Findings

MATLAB R2026a Update 4 is installed with MATLAB, Simulink, Stateflow, and Fuzzy Logic Toolbox. The following required products are missing: Simscape, Simscape Multibody, Simscape Electrical, Control System Toolbox, and Simulink Control Design.

> Superseded by the installation recorded in the baseline-model entry below.

#### Next Steps

- Install the missing products from the MathWorks installer.
- Run `check_environment` until all required products are installed.
- Record the final environment at Gate G0.

---

### November 9, 2026 — Solar Position, Target Angles, and Dual-Axis Baseline

**Status:** Completed (unit-level foundation)

#### Activities

- [x] Implemented `solar_position.m` using the NOAA/Meeus equations.
- [x] Implemented `solar_vector.m`, `panel_normal.m`, and `angle_of_incidence.m`.
- [x] Implemented `target_angles.m` for azimuth and panel-tilt commands.
- [x] Validated the solar position against the NREL SPA golden example.
- [x] Added 19 unit tests in `tests/unit/`; all tests pass.
- [x] Compared fixed, single-axis azimuth, horizontal north–south, and dual-axis configurations for Malang 2026.
- [x] Added `src/analysis/compare_tracker_axes.m` and generated `results/metrics/axis_comparison.csv` and `results/figures/axis_comparison.png`.
- [x] Updated `docs/SYSTEM_DESIGN.md`, `docs/TEST_PLAN.md`, and `src/initialization/setup_project.m` for the dual-axis baseline.

#### Progress

The MATLAB foundation is complete: solar position, coordinate transforms, target-angle generation, and an annual energy screening tool. The NREL SPA golden case matches the reference azimuth to 0.00234° and the geometric elevation to 0.01631°; the equation of time matches to 0.0066 min.

The annual direct-beam proxy for Malang 2026 gives:

| Configuration | Energy (kWh/m²/year) | Gain vs fixed |
|---|---:|---:|
| Fixed, optimal tilt 8° | 2276.6 | — |
| Single-axis azimuth, optimal tilt 43° | 3062.2 | +34.5% |
| Horizontal north–south single-axis | 3115.4 | +36.8% |
| Dual-axis (ideal) | 3264.5 | +43.4% |

The team selected the **dual-axis azimuth–elevation** configuration as the baseline because it directly addresses the multi-axis project brief and gives the highest energy gain. The single-axis azimuth case remains in the analysis for comparison and as a candidate degraded mode.

#### Challenges

- The equation-of-time expression initially returned radians but was treated as degrees, causing an azimuth error of about 4.6°. The NREL reference test caught it.
- `panel_normal` initially defined a 0° tilt as facing north instead of facing up.
- `solar_vector` and `panel_normal` did not expand a scalar angle against a vector.
- The required Simscape and Control System Toolbox products are still not installed, so model construction cannot start. (Resolved later on 2026-11-09.)

#### Decisions

- Baseline axis: dual-axis azimuth–elevation.
- Panel tilt is controlled by the elevation axis; there is no fixed tilt.
- Elevation-axis command is panel tilt, with `targetTilt = 90° - sunElevation`.
- Preliminary tilt range: 0°–85° to avoid the gimbal singularity at zenith.
- Net energy after actuator consumption is the primary performance metric.

#### Next Steps

- Install the five missing products and close Gate G0.
- Obtain formal Gate G1 sign-off.
- Perform the Gate G2 design calculations: panel inertia, gravity torque, motor and gear selection, and diffuse irradiance model.
- Build the Simscape Multibody and Simscape Electrical model at Gate G3.
- Design and test the two PID loops.

---

### November 9, 2026 — Gate G2 Preliminary Actuator Sizing

**Status:** Completed (preliminary)

#### Activities

- [x] Centralized the design parameters in `src/initialization/project_config.m`.
- [x] Refactored `setup_project.m` into a thin loader that copies `cfg` to the base workspace.
- [x] Implemented `src/analysis/design_sizing.m` for the static worst-case sizing of both axes.
- [x] Calculated the panel inertia, gravity torque, friction, and wind allowance.
- [x] Selected the preliminary gear ratios: 100:1 azimuth and 150:1 elevation.
- [x] Verified the motor torque, current, voltage, and speed margins.
- [x] Added `tests/unit/test_design_sizing.m`; the unit suite is now 24/24 passing.
- [x] Added `docs/design/G2_DESIGN_CALCULATIONS.md`.
- [x] Updated `docs/SYSTEM_DESIGN.md` with the G2 parameters.

#### Progress

The preliminary sizing gives a required output torque of 11.4 N·m on the
azimuth axis and 17.06 N·m on the elevation axis. With 100:1 and 150:1 worm
gears at 70% efficiency, both motors require about 0.163 N·m and 3.25 A. The
current limit is 5 A, so the current margin is about 1.75 A. The torque margin
at the current limit is about 1.54 on both axes.

| Quantity | Azimuth | Elevation |
|---|---:|---:|
| Inertia | 8.0 kg·m² | 3.5 kg·m² |
| Gravity torque | 0 N·m | 5.886 N·m |
| Required output torque | 11.4 N·m | 17.06 N·m |
| Motor torque | 0.163 N·m | 0.162 N·m |
| Motor current | 3.26 A | 3.25 A |
| Torque margin | 1.54 | 1.54 |
| Speed margin | 137.5 | 91.7 |

The elevation holding current at tilt 0° is 1.12 A (1.5 W). A self-locking worm
gear or a holding brake can avoid this energy during the night. The decision is
deferred to Gate G3.

#### Challenges

- The first sizing draft used the motor-side friction (0.01 N·m) instead of the
  output-side friction (1.0 N·m). The output-side value is the correct one for
  the torque balance.
- The gravity torque depends on the centre-of-mass offset, which is not known
  from the CAD model yet. A 0.05 m offset is assumed.
- The speed margin is very large because the gear ratios are torque-driven.
  This is acceptable for the preliminary design but should be revisited when a
  commercial motor is selected.

#### Decisions

- Preliminary gear ratios: 100:1 azimuth, 150:1 elevation.
- Preliminary motor: 24 V brushed DC, `K_t = 0.05 N·m/A`, `R = 1.2 Ω`,
  `K_b = 0.05 V·s/rad`, 5 A current limit.
- The final motor and gearbox selection is confirmed at Gate G3 with the
  dynamic model.
- The elevation holding strategy (self-locking gear versus brake) is decided
  at Gate G3.

#### Next Steps

- Install the five missing products and close Gate G0.
- Obtain formal Gate G1 sign-off.
- Build the Simscape Multibody and Simscape Electrical model at Gate G3.
- Confirm the inertia and friction values from the model.
- Compare the self-locking gear and brake options for elevation holding.
- Add the diffuse irradiance model and the net-energy calculation.

---

### November 9, 2026 — Clear-Sky Irradiance and Daily Energy Model

**Status:** Completed (MATLAB-level model)

#### Activities

- [x] Implemented `clear_sky_irradiance.m` with the Meinel direct-beam model.
- [x] Implemented `plane_of_array_irradiance.m` with the isotropic sky model.
- [x] Implemented `energy_metrics.m` for PV and actuator energy integration.
- [x] Implemented `daily_energy_simulation.m` for fixed, azimuth, and dual-axis cases.
- [x] Implemented `compare_daily_energy.m` and generated the daily comparison CSV and PNG.
- [x] Added 10 unit tests in `tests/unit/test_energy_model.m`; the suite is now 34/34 passing.
- [x] Verified the Code Analyzer is clean (excluding the environment settings-file warning).

#### Progress

The MATLAB-side energy model now covers the full chain from solar position to
daily PV energy:

1. `solar_position` gives the sun azimuth and elevation.
2. `clear_sky_irradiance` gives DNI, DHI, and GHI.
3. `plane_of_array_irradiance` applies the isotropic sky model to the panel.
4. `daily_energy_simulation` computes the PV power and daily energy.
5. `energy_metrics` integrates the PV and actuator power into net energy.

The daily results for Malang on 2026-03-21 at 5-minute sampling are:

| Configuration | Daily PV energy (kWh) | Gain vs fixed |
|---|---:|---:|
| Fixed, tilt 8° | 1.8359 | — |
| Single-axis azimuth, tilt 43° | 2.2987 | +25.2% |
| Dual-axis | 2.4487 | +33.4% |

The daily gain is lower than the annual direct-beam proxy (+43.4%) because the
daily model includes the diffuse component and a ground-reflected term. The
seasonal check gives +40.1% on 2026-06-21 and +47.0% on 2026-12-21 for the
dual-axis case. This is the expected behavior: the tracker gain is highest in
the southern summer, when the sun path is longer and the fixed north-facing
panel is less well aligned.

#### Challenges

- The isotropic sky model needs a diffuse fraction. A constant DHI/DNI = 0.10
  is used for the clear-sky screening model; a more detailed model can replace
  it when measured data are added.
- The fixed-panel daily energy is higher in December than in June, even though
  the site is in the southern hemisphere. The reason is that the panel tilt is
  only 8°, so the high December sun is captured well; the north-facing panel
  does not suffer much from the small north–south misalignment.
- The actuator energy is not yet included in the daily simulation because the
  motor and controller model does not exist. The `energy_metrics` function is
  ready to accept the actuator power from the Simulink model.

#### Decisions

- Clear-sky model: Meinel direct beam, constant diffuse fraction 0.10, and
  isotropic sky diffuse on the panel.
- Ground albedo: 0.20.
- PV model: linear efficiency 18% with an 85% system loss factor.
- Fixed reference: tilt 8°, azimuth 0° (north).
- Azimuth reference: fixed tilt 43°, azimuth follows the sun.

#### Next Steps

- Install the five missing products and close Gate G0.
- Build the Simscape model and connect the actuator power to `energy_metrics`.
- Replace the constant diffuse fraction with a measured or scenario-based model.
- Add the cloud, rain, and night scenarios.
- Confirm the annual energy with a full-year daily simulation.

---

### November 9, 2026 — Supervisory Mode and Deadband Logic

**Status:** Completed (MATLAB reference implementation)

#### Activities

- [x] Implemented `src/controllers/tracker_mode_logic.m` as a pure function with explicit state.
- [x] Added the `DAY_TRACK`, `DEADBAND_HOLD`, `NIGHT_STOW`, `CLOUD_HOLD`, and `FAULT_SAFE` modes.
- [x] Added the night-stow hysteresis (enter at 0°, leave above 2°).
- [x] Added the per-axis deadband, wrapped azimuth error, and mechanical-limit clamping.
- [x] Added the latching fault state with an explicit reset.
- [x] Added 15 unit tests in `tests/unit/test_mode_logic.m`; the suite is now 49/49 passing.
- [x] Verified the Code Analyzer is clean (excluding the environment settings-file warning).
- [x] Updated `docs/SYSTEM_DESIGN.md` and `docs/TEST_PLAN.md`.

#### Progress

The supervisor converts the sun position and the measured panel position into a
mode, a target, and a motor-enable command. The mode priority is:

1. `FAULT_SAFE` — both motors disabled; the fault latches until reset.
2. `NIGHT_STOW` — target the stow position and stop when the panel arrives.
3. `CLOUD_HOLD` — hold the previous target and disable the motors.
4. `DAY_TRACK` — update the target when either axis error exceeds the deadband.
5. `DEADBAND_HOLD` — hold the previous target and disable the motors.

The function takes the previous state as an input and returns the next state.
This avoids persistent variables and makes every transition deterministic and
testable. The Stateflow chart or MATLAB Function block at Gate G3 will reproduce
this reference logic.

#### Challenges

- The first version of the deadband-resume test expected `modeChanged` on a
  `DAY_TRACK` to `DAY_TRACK` transition. The test was corrected to go through
  `DEADBAND_HOLD` first, which is the transition that matters.
- The azimuth error must be wrapped to ±180°. Without the wrap, a target of 1°
  and a measured position of 359° would produce a −358° error instead of +2°.
- The night-stow hysteresis needs the previous mode. A purely combinational
  function would chatter when the elevation crosses 0°.

#### Decisions

- Implement the logic as a pure function with explicit state, not with
  persistent variables or globals.
- Default deadband: 0.5° per axis.
- Night stow: enter at or below 0° and leave above 2°.
- Cloud hold: cloud cover at or above 0.8.
- Fault: latch the safe state until `ResetFault` is true and the fault is clear.
- Default stow position: azimuth 0°, tilt 0°.

#### Next Steps

- Implement the discrete PID baseline in plain MATLAB with anti-windup,
  output saturation, and a rate limiter.
- Install the missing products and close Gate G0.
- Reproduce the supervisor as a Stateflow chart in the Simulink model.
- Connect the mode command, controller, actuator, and energy model.
- Add the cloud, rain, night, and fault scenarios.

---

### November 9, 2026 — Baseline Model, One-Click Run, and Repository Cleanup

**Status:** Completed

#### Activities

- [x] Verified the installed products: Simscape, Simscape Multibody, Simscape Electrical, and Control System Toolbox are now available (MATLAB R2026a Update 5).
- [x] Classified Simulink Control Design as optional because the model does not use it.
- [x] Added `models/build_solar_tracker_model.m` to rebuild the baseline model from code.
- [x] Extended `run_project.m` to build the daily solar trajectory, run the model, compute tracking metrics, and save a response figure.
- [x] Fixed the `num2str` duration bug in the demo workflow and merged the workflow into `run_project.m`.
- [x] Fixed the default model inputs so that the From Workspace blocks cannot extrapolate beyond the data range.
- [x] Removed the duplicate `workflows/` folder, the `.bak` file, redundant `.gitkeep` files, empty folders, and generated `slprj/`/`.slxc` artifacts.
- [x] Updated `.gitignore` and corrected the LICENSE copyright holder.

#### Progress

The repository now has a single entry point. `run_project` builds the target
trajectory from the solar position and target-angle functions, runs the baseline
two-axis model, and writes `results/metrics/tracking_metrics.csv` and
`results/figures/tracking_response.png`.

The baseline model remains a control-loop placeholder: the axis plants are
gains plus integrators, not Simscape mechanics. It verifies the trajectory,
signal interfaces, and metric pipeline before the Simscape plant replaces the
placeholder.

#### Challenges

- `num2str(hours(...))` fails because `num2str` does not accept a duration. The
  workflow stopped before the simulation started.
- A two-point From Workspace input extrapolates linearly outside its time range.
  A step from 0° to 10° produced a 500° target at t = 5 s. The default inputs now
  cover the full stop time, and `run_project` always supplies the full
  trajectory.
- The `.m` and `.mlx` workflows had diverged, so neither could be treated as the
  source of truth. Both are replaced by the entry point.

#### Decisions

- `run_project.m` is the only entry point; the `workflows/` folder is removed.
- Simulink Control Design is optional; the six required products are the ones
  actually used by the model and tests.
- Empty placeholder folders are removed. They will be recreated when data or
  libraries are actually added.

#### Next Steps

- Replace the baseline axis plants with the Simscape Multibody and Simscape
  Electrical model.
- Connect the actuator power to the net-energy metric.
- Add model, integration, and scenario tests.
- Close Gate G1 with a formal requirements review.

### November 10, 2026 — Requirements Audit and Explicit Axis Plant

**Status:** Completed (documents) / In Progress (plant integration)

#### Activities

- [x] Created `docs/REQUIREMENTS_CHECKLIST.md`, separating official MathWorks
      requirements from project decisions and unknowns.
- [x] Added a dated 17-week schedule (2026-11-09 → 2027-03-05) to the project
      plan, with one exit check per week.
- [x] Added the Generative AI Usage section to the README.
- [x] Created the Capstone Report skeleton with an evidence requirement per
      section.
- [x] Diagnosed the Simscape port roles experimentally instead of guessing.
- [x] Built `models/build_axis_plant.m`: an explicit DC-motor axis plant from
      Simscape primitives.
- [x] Built `models/verify_axis_plant.m` and passed all three checks.

#### Progress

The axis plant replaces the library DC Motor block with visible equations:

```
V = Ra*i + La*di/dt + Ke*omega
J_eq*domega/dt = Kt*i - T_friction - T_dist/(eta*N)
J_eq = J_load/N^2 + J_motor,   theta_load = theta_motor/N
```

Verification against closed-form results on 2026-11-10:

| Check | Reference | Measured |
|---|---|---|
| No-load steady-state speed at 24 V | 458.015 rad/s | 457.955 rad/s (0.01%) |
| Armature current ceiling | 5 A | 5.000 A |
| Speed rise time | 0.371 s | 0.372 s (0.2%) |

Runtime was measured before committing to the architecture: one axis at
`MaxStep = 0.01 s` costs 2.47 s of wall time per 600 s of simulated time,
which extrapolates to about 5.9 minutes for a 24-hour horizon. A dual-axis
24-hour run therefore stays close to the 10-minute budget in NFR-05, and a
looser `MaxStep` leaves further margin.

#### Challenges

- The MATLAB MCP session moved to an R2026b installation without Simulink,
  while batch R2026a through WSL intermittently failed with
  `UtilAcceptVsock: accept4 failed 110`. Each failure mode had to be identified
  separately before any model work could continue.
- The library DC Motor block exposes four physical ports whose roles are not
  documented in the mask. Connecting the mechanical load produced a current
  spike followed by zero speed, so the block was abandoned in favour of the
  explicit plant.
- Simscape rejects `Col_trq = 0`, so the linear verification uses `1e-6 N*m`.
- The first current-limit design scaled the voltage by `i_limit/|i|`. Feeding
  the measured current back into the voltage created an algebraic loop that the
  discontinuity solver could not resolve, and the current reached 9.98 A
  against a 5 A limit. The replacement clamps the voltage to
  `Ke*omega ± Ra*i_limit`, which is algebraically equivalent to the current
  limit, depends only on a state, and holds exactly.
- Review of the plant found that `Vbus` is declared as a required parameter but
  is never applied to the voltage command, so only the current is bounded and
  the bus voltage is not. Logged as DEF-005 (open) in the test plan rather than
  fixed immediately, because the current tests only command 24 V and would not
  have caught it. The fix is to widen the existing saturation bounds.
- Review of the baseline model found two more mismatches between the
  configuration and the model. Four parameters in `project_config` are declared
  but never read (`Kd`, `rateLimit`, `filterCoefficient`,
  `controllerSampleTime`), so the implemented controller is a PI without a rate
  limit, not the documented PID — DEF-006. Separately, the model runs
  `FixedStep = 1 s`, so the loop actually updates at 1 Hz while the design
  documents 100 Hz — DEF-007. Both are invisible with the placeholder plant and
  both are resolved by the plant integration, which has to rebuild the solver
  and retune the loops anyway.

#### Decisions

- The plant uses lumped-parameter rotational dynamics instead of Simscape
  Multibody. It reproduces the joint dynamics with fewer blocks and no solver
  cost from a multibody assembly, which matters for a 24-hour study.
- The gear is modelled by reflecting the load inertia and dividing the
  disturbance torque by `eta*N`. Gear loss therefore appears in the electrical
  energy, not as a separate accounting term.
- Disturbance input convention: positive `T_dist` opposes the positive
  direction. This is exact for wind and friction; gravity assistance while
  lowering is not captured and is documented as a simplification.

#### Next Steps

- Integrate the plant into `models/solar_tracker.slx` and retune both loops.
- Decide how the plant and the 24-hour energy study share the runtime budget.
- Connect the logged voltage and current to the net-energy metric.

---

### November 10–11, 2026 — R2026b Compatibility Check and Full Test Runner

**Status:** Completed

#### Activities

- [x] Ran the full unit suite on MATLAB R2026b Update 1: 49/49 pass.
- [x] Ran `run_project` on R2026b and compared every metric with R2026a.
- [x] Ran `verify_axis_plant` on R2026b: 3/3 pass.
- [x] Fixed `check_environment` so it no longer demands products the project
      does not use (DEF-008).
- [x] Added an explicit product check to `verify_axis_plant` so a missing
      Simscape installation produces a readable message (DEF-009).
- [x] Added `tests/run_all_tests.m`, a single command that runs every test
      level and prints one summary table.
- [x] Fixed `run_project` so it can be called repeatedly in one session
      (DEF-010).

#### Progress

The two installations were compared directly:

| Check | R2026a Update 5 | R2026b Update 1 |
|---|---|---|
| Unit suite | 49/49 | 49/49 |
| Axis plant | 3/3 | 3/3 |
| Azimuth RMSE | 0.1866° | 0.18664° |
| Tilt RMSE | 0.0778° | 0.07784° |
| Azimuth max error | 3.9422° | 3.9422° |
| Tilt max error | 1.3231° | 1.3231° |

The agreement is exact, not approximate. Both runs use the fixed-step `ode4`
solver, so the same step sequence produces the same numbers on both releases.
This is evidence for the reproducibility requirement that a plain "tests pass"
statement does not provide.

`run_all_tests` runs six stages and reports one table:

| Stage | What it checks | Status field |
|---|---|---|
| environment | required products present | pass/fail |
| unit suite | 50 tests in `tests/unit` | pass/fail |
| axis plant | T1–T4 closed-form checks | pass/skip/fail |
| plant validation | step response and two-hour tracking on the Simscape plant | pass/skip/fail |
| integration | 24 h run, baseline regression, reproducibility | pass/fail |
| actuator sizing | torque, speed, current, voltage margins | pass/fail |
| annual analysis | optional, ordering of the four configurations | pass/fail |

It writes `results/test-reports/test_summary.csv` and, when the installation
has the plugin, JUnit XML. A stage that cannot run is reported as skipped, so a
partial installation still produces a meaningful summary.

#### Challenges

- `ver()` reported only MATLAB, Simulink, and MATLAB Copilot at the start of the
  session, so the first round of work was recorded on the assumption that
  Simscape was unavailable. After the MCP server restarted, the same
  installation reported Simscape, Simscape Battery, Simscape Electrical, and
  Control System Toolbox as installed, and the plant verified 3/3. The earlier
  product assumption was corrected in the test plan rather than left in place.
- `verify_axis_plant` failed once with
  `Expression 'UseLocalSolver * LocalSolverSampleTime - (~UseLocalSolver)' ...
  cannot be evaluated. Memory allocation error.` The message points at a
  Simscape solver parameter, but the cause was host memory pressure: the same
  command passed unchanged once the competing batch process exited.
- A batch run died with exit code `0xc000012d` (`STATUS_COMMITMENT_LIMIT`).
  Both drives were full at the time (C: 44 MB free, D: 175 MB free) and free
  commit charge was under 1 GB. Simulink then warned about low available disk
  space and dropped logged data, and later runs failed with
  `MATLAB:badsubscript`. None of these were code defects, but they made the
  results non-repeatable until disk and memory were freed.
- The R2026b installation is trimmed: it has no `matlab.unittest.plugins`
  package, so `XMLOutputPlugin` cannot be constructed. Adding the plugin
  unconditionally failed the whole suite over a reporting format.
- `run_project` could not be called twice in the same session. Assigning the
  target inputs to the model workspace marks the model as changed, so the
  second call hit the `run_project:UnsavedModel` guard. The reproducibility
  check exposed this immediately, which is exactly what it is for.

#### Decisions

- `run_all_tests` treats an unavailable report plugin as a note, not a failure.
  The summary CSV is the primary evidence and is always written.
- `run_project` clears the model dirty flag after simulating, rather than
  closing the model, so a user can still inspect the block diagram afterwards
  while repeated calls remain possible.
- Environment failures (disk, memory) are documented as host conditions in the
  test plan, not logged as software defects.

#### Next Steps

- Free disk space on C: and D: before the next Simscape run.
- Integrate the plant into `solar_tracker.slx`.

---

### November 11, 2026 — Closed-Loop Tracker on the Simscape Axis Plant

**Status:** Completed

#### Activities

- [x] Build `models/solar_tracker_plant.slx` with two PID loops around the
      explicit axis plants.
- [x] Add the tilt-dependent gravity torque and the azimuth wind torque.
- [x] Implement the full PID: filtered derivative on the measurement, clamped
      integrator, and rate limiter.
- [x] Tune the gains against the plant and validate with a step and a two-hour
      tracking scenario.
- [x] Add plant validation as a stage in `tests/run_all_tests.m`.
- [x] Close DEF-005, DEF-006, and DEF-007.

#### Progress

`solar_tracker_plant.slx` is generated by
`models/build_tracker_plant_model.m`. It keeps the same top-level interface as
the baseline model but replaces each gain-and-integrator axis with the Simscape
DC motor and gear plant from `models/build_axis_plant.m`. Both axes run at the
configured 10 ms control step, with Simscape local solvers at the same rate.

The elevation disturbance is `T = m·g·L·cos(tilt)`, which is largest when the
panel is horizontal and vanishes when it is vertical. The azimuth disturbance
is a constant 2 N·m wind torque (20 % of the 10 N·m sizing allowance).

`models/validate_tracker_plant.m` runs two scenarios and writes
`results/metrics/plant_validation.csv` and
`results/figures/plant_validation.png`. All 14 checks pass:

| Check | Azimuth | Tilt |
|---|---:|---:|
| Rise time 10–90 % | 0.48 s | 0.57 s |
| Overshoot | 8.07 % | 6.84 % |
| Settling time (2 %) | 7.43 s | 7.18 s |
| Steady-state error | 0.011° | 0.007° |
| Peak current | 5.000 A | 5.000 A |
| Tracking RMSE | 0.0108° | 0.0099° |
| Tracking max error | 0.347° | 0.310° |

The tuning result is `Kp = 1.2`, `Ki = 0.3`, `Kd = 0.2`, derivative filter
20 rad/s, and voltage rate limit 2400 V/s.

#### Challenges

- **Algebraic loops across solver boundaries.** The electrical and mechanical
  Simscape networks are separate, so the back-EMF feedback crosses a solver
  boundary. At fixed step with local solvers this is an algebraic loop and is
  rejected. A one-step `Unit Delay` on the speed feedback removed the loop
  without changing the steady-state equations. The same problem appeared at
  tracker level, where the plant output feeds back to the controller; `Memory`
  blocks on the measured angles fixed it.
- **Tilt gravity path.** Tapping the plant output for the gravity torque
  created a second loop. The tap was moved to the measured angle, after the
  `Memory` block.
- **Filtered-derivative bug.** The block was configured as `Kd·s/(s + wf)`,
  which attenuates the effective derivative gain by the filter frequency. With
  `wf = 20 rad/s` the derivative path was 20× too weak, and the step response
  overshot by 74–124 %. The numerator must be `Kd·wf`. After the fix the
  derivative behaved as designed and the gains could be tuned normally.
- **Rate limiter as the dominant overshoot source.** With the derivative fixed,
  overshoot was still 36 % on azimuth. The 48 V/s rate limit delayed braking by
  about half a second. The drive can swing the full 24 V rail inside one 10 ms
  step, so the limit was raised to 2400 V/s; overshoot fell to 8.07 %.
- **Cost of the full-day plant run.** At a 10 ms step, 24 h needs 8.6 million
  fixed steps. The plant runs 60 s in ≈ 2.1 s wall time, so a full day is not
  affordable on the project hardware. The daily energy study therefore remains
  on the reduced-order model, and the plant model is scoped to short-horizon
  control and actuator validation.

#### Decisions

- Keep two models. The reduced-order model is the daily-energy workhorse; the
  plant model is the control and actuator validation model. Each has a gain
  set matched to its own voltage-to-angle gain.
- Apply the derivative to the measurement, not to the error, to avoid kicks at
  target steps and mode changes.
- Enforce the current ceiling as the voltage window
  `Ke·omega ± Ra·currentLimit`, then clamp to the bus rails with `VbusLim`.

#### Next Steps

- Update the capstone report with the controller design and validation results.
- Run a clean-clone verification of the full test suite (R-09).
- Record the 3–5 minute submission video.

---

### November 11, 2026 — Net Energy Accounting

**Status:** Completed

#### Activities

- [x] Add a quasi-static DC-motor energy model for both axes.
- [x] Integrate actuator energy into the daily energy simulation.
- [x] Report net energy and net gain in the daily comparison.
- [x] Add a unit test for the holding current against the Gate G2 figure.

#### Progress

`src/energy/tracker_actuator_energy.m` estimates the electrical power of both
axis motors from the commanded angle trajectory. The daily comparison now
reports captured PV energy, actuator energy, net energy, and the gain against
the fixed panel for both the PV and the net figures.

| Configuration | PV (kWh) | Actuator (kWh) | Net (kWh) | PV gain | Net gain |
|---|---:|---:|---:|---:|---:|
| Fixed, tilt 8° | 1.836 | 0 | 1.836 | — | — |
| Single-axis azimuth | 2.299 | 0.009 | 2.289 | +25.2% | +24.7% |
| Dual-axis | 2.449 | 0.036 | 2.413 | +33.4% | +31.4% |

The elevation holding current at tilt 0° comes out at 1.121 A and 1.51 W,
which matches the 1.12 A and 1.5 W in the Gate G2 calculation. That agreement
is now a unit test, so the energy model and the static sizing cannot drift
apart silently.

#### Challenges

- The daily energy comparison previously passed a zero actuator power to
  `energy_metrics`, so the headline gain was a captured-energy gain, not the
  net gain the project set out to report. The table looked complete because the
  column was named `PvEnergy_kWh`; the objective was not met until the motor
  power was actually estimated.
- A full electromagnetic simulation cannot run for 24 h at a 10 ms step. The
  quasi-static torque balance is the compromise: it uses the same motor, gear,
  and friction parameters as the Simscape plant, and it is validated against
  the plant at the holding point.

#### Decisions

- Keep the drive model conservative: no regeneration, no self-locking gear, and
  the panel held against gravity all night.
- Report both gains. The PV gain answers how much extra light is captured; the
  net gain answers whether tracking is worth it.

#### Next Steps

- Mirror the net-energy result in the capstone report.
- Run the full suite again after the energy change (unit count is now 50).

---

### November 12, 2026 — A Test Failure That Was Not a Model Failure

**Status:** Completed

#### Activities

- [x] Trace `MATLAB:badsubscript` in the plant validation to its real cause.
- [x] Stop the Simulation Data Inspector from managing runs on disk.
- [x] Apply the setting from both entry points, before any simulation starts.
- [x] Re-run the full suite and confirm every stage.
- [x] Rebuild both models from their scripts and re-run the checks.
- [x] Add one command that exercises every executable file.

#### Progress

The full suite started failing on a host with almost no free disk space. The
plant validation stopped on a missing element in the logged dataset, which reads
like an indexing bug in the analysis code. It was not. Simulink had warned that
it was deleting archived runs because of low disk space, and then that it was
turning off recording of all data. Once recording is off, the dataset is
incomplete and the validation indexes past its end.

`src/initialization/configure_sdi_preferences.m` now turns off SDI auto-archive
and sets the archive run limit to zero. Nothing in the project reads the SDI
copy of a run: every result comes from the returned `SimulationOutput`. The
function is called by `setup_project` and at the top of `run_all_tests`, so the
setting is in place before the first simulation of the session.

The full suite then passed 7/7 stages, including the annual axis analysis, and
50/50 unit tests, with no low-disk warning anywhere in the log.

| Stage | Result | Detail |
|---|---|---|
| environment | PASS | all required products installed |
| unit suite | PASS | 50/50 passed |
| axis plant | PASS | T1–T4 |
| plant validation | PASS | 14/14 checks |
| integration | PASS | RMSE 0.1866/0.0778° |
| actuator sizing | PASS | current 1.74/1.75 A |
| annual analysis | PASS | 2277/3062/3115/3265 kWh/m² |

A forced rebuild of both models from their build scripts found one more small
issue. The builders saved the file and left the model open in a modified state,
so the next script that closed it in the same session was refused with
`Unable to close the model 'solar_tracker' because it has been changed`. Both
builders now call `close_system(modelName, 0)` right after `save_system`
(DEF-012). The rebuilt models still pass 4/4 axis checks and 14/14 plant checks,
so the models are reproducible from the scripts and not hand-edited.

`tests/run_everything.m` now runs every executable file in dependency order:
each pure function once with a known input, both model builds, the axis and
plant checks, the baseline simulation, both energy comparisons, the unit suite,
and `run_all_tests` at the end. It reports one line per step and continues after
a failure. The final run passed 16 of 16 steps. Writing it found one wrong
assumption in the smoke checks: a panel facing the sun does not receive the
global horizontal irradiance, it receives the direct normal irradiance plus its
share of the diffuse and ground-reflected light. The check now asserts the
physical inequality (POA at normal incidence is not below DNI) instead of an
equality that was never true.

Running the same steps by hand in the MATLAB desktop exposed one more nuisance.
`verify_axis_plant` builds a temporary model, and that model had a fixed name,
so Simulink warned about the name shadowing a workspace variable or a file on
the path before the checks even started. The temporary model name now ends in a
unique token from `tempname` (DEF-013), and the warning is gone.

#### Challenges

- The first version of the fix looked correct and did nothing. It guarded each
  call with `exist(name)`, and `exist` returns `0` for a package method such as
  `Simulink.sdi.setAutoArchiveMode`, so the calls were skipped without an error.
  The preference read-back showed the old values (`autoArchive = 1`,
  `limit = -1`), which is how the mistake was found. The guard is now a plain
  `try`/`catch`, and the effect is checked by reading the preferences back.
- The failure mode is misleading by nature. A missing dataset element is an
  indexing error in the code that reads it, but the cause sat in the host's free
  space. This is recorded as DEF-011 so the next person does not debug the
  analysis code first.

#### Decisions

- Keep SDI recording off rather than reducing the number of logged signals. The
  validation needs the full signal set; the SDI archive is the part that is
  unnecessary.
- Set the preference in code, not in the MATLAB preferences dialog, so a fresh
  clone and a batch run behave the same way.

#### Next Steps

- Run a clean-clone verification of the full test suite (R-09).
- Record the 3–5 minute submission video.

---

### November 12, 2026 — Running the Project Like a Notebook

**Status:** Completed

#### Activities

- [x] Add `run_steps.m`, a single file with twelve `%%` sections
- [x] Put the sections in the same order as `tests/run_everything.m`
- [x] Run sections 1–10 in one batch session and check every line of output
- [x] Document the runner in the README

#### Progress

The project could be run from one command, but reviewing it meant copying
commands into the Command Window one at a time. `run_steps.m` turns the same
sequence into twelve sections. In the MATLAB Editor, each `%%` line starts a
section with its own **Run Section** button, so a section can be run alone with
Ctrl+Enter and the output appears in the Command Window. **Run** executes all
twelve in order.

The script derives the project root from `mfilename('fullpath')`, so it works
from any current folder, and section 1 adds the source, test, and model folders
to the path once per session.

#### Challenges

- A `.mlx` live script would show output inline, but it is a binary zip
  container: it does not diff, it cannot be reviewed in a pull request, and it
  needs the Live Editor. An `.ipynb` needs the MATLAB kernel for Jupyter, which
  is an extra install. A plain `.m` file gives the same cell behaviour, stays
  text, and needs nothing beyond MATLAB.
- Section 5 calls `validate_tracker_plant`, which throws on failure, so the
  assert that follows it can never fire in a correct build. It is kept as a
  guard for the day the function changes to return instead of throw.

#### Decisions

- Plain `.m` with `%%` sections, committed next to `run_project.m`, rather than
  a notebook format.
- Keep the section order identical to the all-in-one runner, so the two entry
  points cannot drift apart.

#### Next Steps

- Clean-clone verification (R-09) once the work is committed.
- Record the submission video.

---

## Development Update Template

Use this template whenever a new project activity or milestone takes place.

### [Date] — [Activity Title]

**Status:** Planning / In Progress / Completed

#### Activities

- [ ] Activity 1
- [ ] Activity 2
- [ ] Activity 3

#### Progress

Describe the work completed during this activity.

#### Challenges

Record problems, limitations, or difficulties encountered.

#### Decisions

Document important decisions made during the development process.

#### Next Steps

Describe the planned activities for the next stage.

---

## Documentation Guidelines

- Keep entries in chronological order.
- Record actual progress rather than assumptions.
- Document important technical decisions.
- Record challenges and their solutions.
- Update this log whenever meaningful progress is made.

---

<p align="center">
  <i>Every step matters. Every update becomes part of the project history.</i>
</p>
