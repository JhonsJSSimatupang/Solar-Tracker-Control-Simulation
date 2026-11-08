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
