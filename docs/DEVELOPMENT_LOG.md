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

**Status:** Blocked (installation pending)

#### Activities

- [x] Audited the installed MATLAB products.
- [x] Added `tests/check_environment.m`.
- [x] Added `docs/SETUP.md` with installation steps and the Gate G0 checklist.
- [ ] Install the missing toolboxes.
- [ ] Re-run the environment check.

#### Findings

MATLAB R2026a Update 4 is installed with MATLAB, Simulink, Stateflow, and Fuzzy Logic Toolbox. The following required products are missing: Simscape, Simscape Multibody, Simscape Electrical, Control System Toolbox, and Simulink Control Design.

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
- The required Simscape and Control System Toolbox products are still not installed, so model construction cannot start.

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
