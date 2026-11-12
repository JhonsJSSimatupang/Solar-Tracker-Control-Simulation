# 🤖 AI Usage Log

## Solar Tracker Control Simulation

> This log records every non-trivial use of generative AI in the project. It exists to satisfy the MathWorks Generative AI Guidelines and to protect the team's academic integrity.

---

## 1. Rules

### Allowed

- Explaining concepts and MATLAB/Simulink syntax.
- Drafting boilerplate, comments, and documentation.
- Debugging error messages.
- Suggesting test cases.
- Reviewing code for style or possible issues.

### Not allowed

- Submitting code that the team cannot explain.
- Generating simulation results or data.
- Copying AI output without testing.
- Using AI to write the core engineering justification without team verification.
- Hiding AI contributions.

### Try-first rule

- Write the problem statement and attempt a manual solution before asking AI.
- Use AI to compare approaches or unblock you, not to replace the attempt.
- Core design decisions must be made and documented by the team first.

### Required

- Log every non-trivial AI interaction.
- Review and test all AI-assisted output.
- Add a code comment for non-trivial AI-assisted changes.
- Be ready to explain or modify the work during evaluation.

---

## 2. Human Verification Protocol

For every non-trivial AI-assisted change:

1. Read the output line by line.
2. Explain it to a teammate without the AI chat open.
3. Run it on at least two test cases.
4. Change one parameter and predict the effect before running.
5. Record the verification in this log.
6. Commit only after the verification passes.

### Code comment format

```matlab
% AI-assisted: <what the AI helped with>.
% Reviewed and tested by <name> on <YYYY-MM-DD>.
```

---

## 3. Log

| ID | Date | Team member | Tool / model | Purpose | Prompt summary | Output used | Verification performed | Files affected |
|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-11-09 | Jhons | OpenCode / DeepSeek | Repository structure review | Asked for a recommended repository structure | Directory layout and README outline | Reviewed against MathWorks repository guidelines; `run_project` tested in MATLAB | `README.md`, `run_project.m`, `.gitignore`, `docs/` |
| AI-002 | 2026-11-09 | Jhons | OpenCode / DeepSeek | Solar position implementation and unit tests | Asked for a NOAA/Meeus implementation, NREL SPA validation, and unit tests | `solar_position.m`, `solar_vector.m`, `panel_normal.m`, `angle_of_incidence.m`, `test_solar_position.m` | NREL SPA golden case reproduced; 10/10 tests pass; equations reviewed line by line; parameter variation checked | `src/sun_position/`, `tests/unit/test_solar_position.m` |
| AI-003 | 2026-11-09 | Jhons | OpenCode / DeepSeek | Target angles and axis energy comparison | Asked for the panel-tilt conversion and an annual comparison of fixed, single-axis, and dual-axis trackers | `target_angles.m`, `compare_tracker_axes.m`, `test_target_angles.m`, `test_axis_comparison.m` | 19/19 tests pass; annual values reproduced in MATLAB; CSV and PNG inspected; tilt sweep checked | `src/sun_position/target_angles.m`, `src/analysis/compare_tracker_axes.m`, `tests/unit/`, `results/` |
| AI-004 | 2026-11-09 | Jhons | OpenCode / DeepSeek | Dual-axis design documentation update | Asked to update the design, test plan, and parameters after the team selected dual-axis | `SYSTEM_DESIGN.md`, `TEST_PLAN.md`, `setup_project.m`, `README.md` | Cross-checked against the official project brief; tests rerun after the changes; team decision recorded in the development log | `docs/`, `src/initialization/setup_project.m`, `README.md` |
| AI-005 | 2026-11-09 | Jhons | OpenCode / DeepSeek | Gate G2 actuator sizing | Asked for a static torque, current, voltage, and speed sizing for both axes and a reproducible design note | `design_sizing.m`, `test_design_sizing.m`, `G2_DESIGN_CALCULATIONS.md`, `project_config.m` | Torque balance, gravity term, and current calculation checked by hand; 24/24 tests pass; Code Analyzer clean; results compared with the motor nameplate values | `src/analysis/design_sizing.m`, `tests/unit/test_design_sizing.m`, `docs/design/G2_DESIGN_CALCULATIONS.md`, `docs/SYSTEM_DESIGN.md` |
| AI-006 | 2026-11-09 | Jhons | OpenCode / DeepSeek | Clear-sky irradiance and daily energy model | Asked for a Meinel/isotropic clear-sky model, POA irradiance, energy integration, and daily comparison | `clear_sky_irradiance.m`, `plane_of_array_irradiance.m`, `energy_metrics.m`, `daily_energy_simulation.m`, `compare_daily_energy.m`, `test_energy_model.m` | Hand-checked zenith DNI, air-mass DNI, horizontal-panel POA = GHI, and 2 h integration; 34/34 tests pass; daily CSV and PNG inspected; Code Analyzer clean | `src/energy/`, `tests/unit/test_energy_model.m`, `results/metrics/daily_energy_comparison.csv`, `results/figures/daily_energy_comparison.png` |
| AI-007 | 2026-11-09 | Jhons | OpenCode / DeepSeek | Supervisory mode, deadband, and fault-safe logic | Asked for a pure-function supervisor with day, deadband, night, cloud, and fault modes plus tests | `tracker_mode_logic.m`, `test_mode_logic.m` | Mode priority, azimuth wrap, hysteresis, and limit clamping reviewed line by line; 15/15 mode tests pass; full suite 49/49; Code Analyzer clean | `src/controllers/tracker_mode_logic.m`, `tests/unit/test_mode_logic.m` |
| AI-008 | 2026-11-09 | Jhons | OpenCode / DeepSeek | Baseline model, one-click run, and repository cleanup | Asked to merge the demo workflow into `run_project`, fix the duration and extrapolation bugs, and remove duplicate files | `run_project.m`, `build_solar_tracker_model.m`, `solar_tracker.slx`, `.gitignore`, `LICENSE` | 49/49 tests pass; model simulates end-to-end; `run_project` regenerates the metrics and figure; removed files verified as duplicates or generated artifacts | `run_project.m`, `models/`, `.gitignore`, `LICENSE`, `docs/` |
| AI-009 | 2026-11-10 | Jhons | OpenCode / DeepSeek | Explicit Simscape DC-motor axis plant | Asked for a plant built from Simscape primitives with the electrical, mechanical, and gear equations visible, plus a verification against closed-form results | `build_axis_plant.m`, `verify_axis_plant.m`, `SYSTEM_DESIGN.md` §7.4–7.5 | Port roles determined experimentally, not assumed; three checks pass (steady state 0.01%, current ceiling exact, rise time 0.2%); the first current-limit design created an algebraic loop and was replaced by a voltage-window formulation derived by hand | `models/build_axis_plant.m`, `models/verify_axis_plant.m`, `docs/SYSTEM_DESIGN.md`, `docs/TEST_PLAN.md` |
| AI-010 | 2026-11-10 | Jhons | OpenCode / DeepSeek | Independent review of the plant and baseline model | Asked for a read-through of `build_axis_plant.m` and `build_solar_tracker_model.m` to find anything the passing tests would not catch | `docs/TEST_PLAN.md` §14, `docs/DEVELOPMENT_LOG.md`, `docs/REQUIREMENTS_CHECKLIST.md` | Three defects found by inspection, not by test: unused `Vbus` (DEF-005), four unused configuration parameters (DEF-006), and an actual control rate of 1 Hz against a documented 100 Hz (DEF-007). None was fixed immediately; each was logged with a concrete resolution so the tests that pass are not mistaken for full coverage | `docs/TEST_PLAN.md` §14, `docs/REQUIREMENTS_CHECKLIST.md` FR-07 and NFR-03 |
| AI-011 | 2026-11-10 | Jhons | OpenCode / DeepSeek | R2026b compatibility check and environment-check fix | Asked to verify that the project runs on MATLAB R2026b as well as R2026a | `tests/check_environment.m`, `models/verify_axis_plant.m`, `docs/TEST_PLAN.md` §2.1 | Ran both entry points on R2026b rather than assuming compatibility; the unit suite and `run_project` give bit-identical results across releases, and the axis plant passes 3/3 on both. Removed two products from the required list that the project does not use, and replaced a Simulink-internal error with an explicit product message. The first `ver()` reading in the session was wrong; the product list was re-read after the MCP restart and the test plan corrected | `tests/check_environment.m`, `models/verify_axis_plant.m`, `docs/TEST_PLAN.md` |
| AI-012 | 2026-11-11 | Jhons | OpenCode / DeepSeek | Single-command test runner | Asked for one entry point that runs every test level and reports pass, fail, or skip without hiding partial installations | `tests/run_all_tests.m`, `run_project.m` (DEF-010), `docs/TEST_PLAN.md` §2, `docs/DEVELOPMENT_LOG.md`, `README.md` | Six stages exercised one by one in MATLAB; the runner exposed a real defect (a second `run_project` call in the same session failed on the dirty-model guard) which was fixed and re-tested; the missing JUnit plugin on the trimmed R2026b installation is treated as a note, not a failure; Code Analyzer clean | `tests/run_all_tests.m`, `run_project.m`, `docs/`, `README.md` |
| AI-013 | 2026-11-11 | Jhons | OpenCode / DeepSeek | Closed-loop tracker model on the Simscape axis plant | Asked to wrap two full PID loops around the explicit axis plants, add the tilt gravity and wind disturbances, and produce a step and tracking validation | `models/build_tracker_plant_model.m`, `models/validate_tracker_plant.m`, `models/solar_tracker_plant.slx`, `project_config.m` (plant gains, `windMeanTorque`), `build_axis_plant.m` (`wDelay`, `VbusLim`), `verify_axis_plant.m` (T4) | Every algebraic-loop and sign error was found by running the model, not by reading it: the cross-network back-EMF path needed a Unit Delay, the tilt gravity path needed to tap the measured angle, and the filtered derivative initially used the wrong numerator (`Kd` instead of `Kd*wf`), which hid a factor-of-20 gain error until the step response overshot by 74 %. Gains were then tuned by sweep, not guessed. 14/14 validation checks and 4/4 plant checks pass; Code Analyzer clean | `models/`, `src/initialization/project_config.m`, `tests/run_all_tests.m`, `docs/`, `README.md` |
| AI-014 | 2026-11-12 | Jhons | OpenCode / DeepSeek | Diagnosing a test failure caused by the host disk, not the model | Asked why the plant validation failed with `MATLAB:badsubscript` on a machine with almost no free disk space | `src/initialization/configure_sdi_preferences.m`, `setup_project.m`, `tests/run_all_tests.m`, `README.md` | The error was traced to the Simulation Data Inspector disabling logging when free disk space runs out, which leaves dataset elements missing. Two separate mistakes were caught by running the code rather than reading it: the first guard used `exist` on a package method, which returns 0 even when the call is valid, so the preferences were silently never applied. Verified with `getAutoArchiveMode`/`getArchiveRunLimit` returning 0/0, then ran the full suite (6/6 stages, 50/50 unit tests) with no low-disk warning. A forced model rebuild afterwards exposed a second, unrelated nuisance: both builders left the saved model open and dirty, so a later close raised `Unable to close the model 'solar_tracker' because it has been changed`. Both builders now close the model after saving; a rebuild plus the axis and plant checks still give 4/4 and 14/14 | `src/initialization/configure_sdi_preferences.m`, `src/initialization/setup_project.m`, `models/build_solar_tracker_model.m`, `models/build_tracker_plant_model.m`, `tests/run_all_tests.m`, `README.md`, `docs/` |
| AI-015 | 2026-11-12 | Jhons | OpenCode / DeepSeek | One command that runs every executable file | Asked for a way to run the whole project, without skipping any file, from a single command | `tests/run_everything.m`, `README.md`, `docs/TEST_PLAN.md` §2, `docs/DEVELOPMENT_LOG.md` | Every call in the driver was exercised in MATLAB before being documented. Two smoke assumptions were wrong and were corrected after running, not by reading: `plane_of_array_irradiance` needs the irradiance struct as a fifth input, and a sun-facing panel does not see the global horizontal irradiance. The finished driver passes 16/16 steps, including the seven-stage suite | `tests/run_everything.m`, `README.md`, `docs/` |
| AI-016 | 2026-11-12 | Jhons | OpenCode / DeepSeek | Shadowing warning from the temporary plant model | Reported a Simulink warning during a manual run: the model name `axis_plant_test` was shadowing another name in the workspace or path | `models/verify_axis_plant.m` (unique model name), `docs/TEST_PLAN.md` (DEF-013) | Reproduced the warning condition deliberately by creating a variable with that exact name, then confirmed the fix by calling the function twice in the same session: no warning, 4/4 checks both times | `models/verify_axis_plant.m`, `docs/` |
| AI-017 | 2026-11-12 | Jhons | OpenCode / DeepSeek | Notebook-style runner | Asked for a way to run the project section by section, like Colab, instead of copying commands into the Command Window | `run_steps.m`, `README.md` | Chose a plain `.m` file with `%%` sections over `.mlx` and `.ipynb`: it stays text, diffs cleanly in git, and needs no extra tooling. Every section was run in MATLAB before being documented; sections 1-10 were executed in one batch session and checked line by line | `run_steps.m`, `README.md` |

> Add one row per session. Keep prompt summaries short but specific.

---

## 4. Disclosure Statement

Use this statement in the final report and, where relevant, in the README:

> This project used generative AI tools for [purpose, e.g., code scaffolding, documentation editing, and debugging assistance]. All AI-assisted output was reviewed, tested, and adapted by the authors. The authors understand and can reproduce every part of the submitted work.

Replace the bracketed text with the actual uses recorded in this log.

---

## 5. Review Checklist

Before submission:

- [ ] Every non-trivial AI interaction is logged.
- [ ] Every AI-assisted file has been reviewed by a team member.
- [ ] Every AI-assisted function has a test.
- [ ] The team can explain the complete workflow without the AI chat.
- [ ] The disclosure statement is included in the report.
- [ ] No AI-generated data or results are included.

---

<p align="center">
  <i>Use AI to learn faster, not to skip the learning.</i>
</p>
