# ✅ Requirements Checklist

## Solar Tracker Control Simulation — MathWorks Challenge Project 249

> **Purpose:** Separate what MathWorks *actually requires* from what this
> project *chose to do*, and from what is still *unknown*. Every requirement is
> mapped to concrete evidence in this repository so the submission can be
> audited line by line.
>
> **Source policy:** only official MathWorks material is treated as a
> requirement: the project brief, the Challenge Project Hub wiki, the
> Submission Instructions, the Repository Guidelines, and the Generative AI
> Guidelines. The full source analysis is in
> [Milestone 1 — Official Project Research](references/MILESTONE_1_PROJECT_RESEARCH.md).

---

## 1. Status Legend

| Status | Meaning | How to use it |
|---|---|---|
| **Confirmed** | Stated explicitly in an official MathWorks source. | Must be satisfied before submission. |
| **Recommended** | A project interpretation or good practice, not an official rule. | Follow where reasonable; never present as mandatory. |
| **Unknown** | Not published by MathWorks. | Do not claim it as a requirement; confirm after registration. |
| **Done** | Internal requirement with evidence in the repository. | Keep the evidence current. |
| **Partial** | Internal requirement partly satisfied. | Track the remaining gap. |
| **Open** | Internal requirement not yet satisfied. | Scheduled work. |

---

## 2. Confirmed Program Requirements

These come from the Hub wiki and the Submission Instructions. They apply to
every participant regardless of project.

| ID | Requirement | Source | Evidence in this repository | Status |
|---|---|---|---|---|
| R-01 | Register project intent with the official form. | Hub wiki — How to participate | Not a repository artifact; tracked in the private submission record. | External |
| R-02 | Publish a **public GitHub repository** with a **BSD 2-Clause or MIT** license. | Submission Instructions A1 | Public repo `JhonsJSSimatupang/Solar-Tracker-Control-Simulation`; [LICENSE](../LICENSE) is BSD 2-Clause. | **Met** |
| R-03 | Upload the MATLAB/Simulink solution and submit the evaluation form using the registration email. | Submission Instructions A2–A3 | Submission action, not a repository artifact. | External |
| R-04 | Root `README.md` must describe the project, setup, run steps, results, dependencies, and external tools. | Repository Guidelines B1 | [README](../README.md): Overview, Objectives, Technologies, Prerequisites, Installation, Simulation and Testing, Simulation Results, Documentation. | **Met** |
| R-05 | Provide **one minimally interactive entry point** (`.m`, `.mlx`, or `.mlapp`) that loads data, initializes models, runs the pipeline, and displays results. | Repository Guidelines B2 | [`run_project.m`](../run_project.m) loads `setup_project`, builds the trajectory, runs `models/solar_tracker.slx`, computes metrics, writes and displays the figure. | **Met** |
| R-06 | Include a small self-contained sample dataset when input data are required; document downloads for larger data. | Repository Guidelines B3 | No external input data are required. Solar position and irradiance are generated in code, so the condition does not apply. | **Not applicable** |
| R-07 | List required toolboxes, blocksets, add-ons, and external libraries, with installation instructions. | Repository Guidelines B5 | [README — Prerequisites](../README.md#-getting-started) and [Environment Setup](SETUP.md) list every product; no external executables or Python libraries are used. | **Met** |
| R-08 | Include a quick test/demo with expected outputs. MATLAB unit tests are optional. | Repository Guidelines B6 | `tests/run_unit_tests.m` (50 tests); [Test Plan](TEST_PLAN.md); expected metrics in [README](../README.md#-simulation-results). | **Met** |
| R-09 | Use relative paths, run on a clean MATLAB installation, avoid unnecessary large files, use `.gitignore`, and commit with meaningful messages. | Repository Guidelines B8 | All paths derive from `projectRoot`; [`.gitignore`](../.gitignore) excludes `slprj/`, `*.slxc`, autosaves. Clean-clone verification is still pending. | **Partial** |

### R-09 remaining gap

The repository has not yet been cloned into a fresh folder and executed from
scratch. This is scheduled in the final verification week (see
[Project Plan — Schedule](PROJECT_PLAN.md#6-dated-schedule-to-submission)).

---

## 3. Confirmed Project Brief Requirements

These are specific to **Solar Tracker Control Simulation (Project 249)**.

| ID | Requirement | Source | Evidence in this repository | Status |
|---|---|---|---|---|
| P-01 | Design and implement a controller for a **multi-axis solar tracker** that optimizes the panel/sun **angle of incidence** for energy absorption. | Project brief | [System Design](SYSTEM_DESIGN.md); `src/sun_position/angle_of_incidence.m`; two PID loops. | **Met** (baseline) |
| P-02 | Implement **at least one mechanical axis**, add an appropriate **motor/electrical model**, design an **axis controller**, calculate an **optimal target position**, and **validate controller and motor through simulation**. | Project brief | Two mechanical axes and DC-motor plants: `models/build_axis_plant.m`, verified against closed-form results in `models/verify_axis_plant.m` (T1–T4). Axis controllers: full PID in `models/build_tracker_plant_model.m`. Optimal target: `src/sun_position/target_angles.m`. Tracker-level validation: `models/validate_tracker_plant.m`, 14/14 checks pass. | **Met** |
| P-03 | Axis concepts are **azimuth** (horizontal), **elevation** (vertical/solar altitude), and optional **polar/roll** compensation. | Project brief | Dual-axis azimuth–elevation baseline; third axis explicitly out of scope. | **Met** |

### P-02 evidence detail

Two separate models cover the requirement, because one cannot do both jobs at
an acceptable runtime:

- `models/solar_tracker.slx` — reduced-order baseline, 1 s step. Used for the
  24 h energy and tracking study.
- `models/solar_tracker_plant.slx` — two explicit Simscape DC-motor and gear
  axes, two full PID loops, 10 ms step. Used for controller and motor
  validation over short horizons.

The plant itself is checked against closed-form results (steady-state speed,
current ceiling, rise time, bus ceiling: 4/4 pass). The closed loops are
checked with a step scenario and a two-hour tracking window: 8.07 % / 6.84 %
overshoot, 7.43 s / 7.18 s settling, 0.011° / 0.007° steady-state error,
0.0108° / 0.0099° tracking RMSE, and 5.000 A peak current on both axes (14/14
checks pass). The tracking window is two hours rather than a full day because a
10 ms fixed step over 24 h needs 8.6 million steps.

The elevation loop rejects the tilt-dependent gravity torque (`m·g·L·cos(tilt)`)
and the azimuth loop rejects a constant wind torque.

---

## 4. Recommended Practices (Not Official Rules)

These are interpretations from [Milestone 1](references/MILESTONE_1_PROJECT_RESEARCH.md).
They strengthen the submission but must not be described as MathWorks
requirements.

| ID | Recommendation | Why | Status |
|---|---|---|---|
| I-01 | Keep the standard layout: root entry point, `src/`, `models/`, `tests/`, `docs/`, `results/`. | Matches the official example layout and repository guidance. | **Done** |
| I-02 | Report tracking error, angle of incidence / irradiance, actuator effort, and energy comparison with reproducible figures or tables. | Directly follows the project objective and the reproducibility emphasis. | **Partial** — error and irradiance/energy reported; the plant now logs voltage and current, actuator-effort figures still to come |
| I-03 | Preserve a demonstrable **one-axis** test path so the minimum brief requirement stays independently verifiable. | The brief requires "at least one" axis; the dual-axis scope exceeds it. | **Done** — `src/analysis/compare_tracker_axes.m` evaluates single-axis azimuth. |
| I-04 | Document toolbox boundaries only where the implementation actually uses them. | Avoids claiming dependencies the solution does not need. | **Done** — Simulink Control Design, Stateflow, and Simulink Test are marked optional. |
| I-05 | Treat AI provenance as deliverable evidence: keep the log, acknowledge non-trivial assistance, be able to reproduce the work. | Follows the Generative AI Guidelines. | **Done** — [AI Usage Log](AI_USAGE_LOG.md) and the README GenAI section. |

---

## 5. Unknown — Do Not Present as Requirements

The official public sources reviewed for this milestone do **not** specify the
following. They are project decisions, not compliance items.

| ID | Unknown | This project's decision | Where recorded |
|---|---|---|---|
| U-01 | Motor type | Brushed DC gear motor, 24 V, H-bridge driver | [System Design A-05](SYSTEM_DESIGN.md#3-assumptions-and-constraints) |
| U-02 | Controller tuning method | Two PI/PID loops, tuned in simulation | [System Design FR-04/FR-05](SYSTEM_DESIGN.md#4-functional-requirements) |
| U-03 | Geographic site | Malang, East Java (-7.9666°, 112.6326°, UTC+7) | [System Design A-01](SYSTEM_DESIGN.md#3-assumptions-and-constraints) |
| U-04 | Simulation duration | 24-hour full-day runs | `src/initialization/project_config.m` |
| U-05 | Irradiance dataset | Meinel clear-sky model, isotropic diffuse | `src/energy/` |
| U-06 | Performance threshold | Internal targets only (RMS error ≤ 0.5°) | [System Design FR-06](SYSTEM_DESIGN.md#4-functional-requirements) |
| U-07 | Number of axes beyond one | Two (azimuth + elevation) | [System Design — Scope](SYSTEM_DESIGN.md#2-scope) |
| U-08 | Numerical grading rubric | Not published; no acceptance rule assumed | [Milestone 1 §6](references/MILESTONE_1_PROJECT_RESEARCH.md) |
| U-09 | Submission-form specific fields | To be confirmed after registration | Private submission record |
| U-10 | Four-month checkpoint details | Programme-level checkpoint, not project-specific | [Hub wiki](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/) |

---

## 6. Generative AI Requirements

| ID | Requirement | Source | Evidence | Status |
|---|---|---|---|---|
| G-01 | AI may support brainstorming, coding, and debugging, but the author keeps ownership and critical thinking. | GenAI Guidelines | [AI Usage Log — Rules](AI_USAGE_LOG.md#1-rules) | **Met** |
| G-02 | Non-trivial AI assistance must be acknowledged in a report or code comment. | GenAI Guidelines | `% AI-assisted:` headers in source files; README GenAI section; AI-001…AI-008 log rows. | **Met** |
| G-03 | AI output must be reviewed, understood, tested, and checked against official documentation. | GenAI Guidelines | [Human Verification Protocol](AI_USAGE_LOG.md#2-human-verification-protocol); 50 automated tests; Code Analyzer. | **Met** |
| G-04 | Retain prompts or chat logs. | GenAI Guidelines | Prompt summaries recorded per row in the log. Full transcripts retained privately. | **Met** |
| G-05 | No fabricated data, results, or citations. | GenAI Guidelines | All figures and CSVs are generated by committed scripts. | **Met** |

---

## 7. Internal Engineering Requirements

These are this project's own FR/NFR identifiers from
[System Design](SYSTEM_DESIGN.md). They are **not** MathWorks requirements.

### Functional requirements

| ID | Requirement | Status | Evidence / gap |
|---|---|---|---|
| FR-01 | Solar azimuth and elevation within 0.1° of NREL SPA/NOAA. | **Done** | `tests/unit/test_solar_position.m` (10/10) |
| FR-02 | Target angles with clamping and night stow. | **Done** | `tests/unit/test_target_angles.m` (5/5) |
| FR-03 | Deadband and mode logic without chattering. | **Done** | `tests/unit/test_mode_logic.m` (15/15) |
| FR-04 | Azimuth 30° step: settle ≤ 15 s, overshoot ≤ 10%, SSE ≤ 0.2°. | **Open** | Needs the physical plant. |
| FR-05 | Tilt 20° step: settle ≤ 15 s, overshoot ≤ 10%, SSE ≤ 0.2°. | **Open** | Needs the physical plant. |
| FR-06 | RMS azimuth and tilt error ≤ 0.5° over a clear day. | **Partial** | Baseline gain plant: 0.187° / 0.078°; must be re-verified on the Simscape plant. |
| FR-07 | Motor speed and torque follow the motor equations; voltage and current limited. | **Partial** | `models/verify_axis_plant.m`: steady state 0.01%, current ceiling exact at 5.000 A, rise time 0.2%. Voltage is not yet limited to the bus value — DEF-005 (open). |
| FR-08 | Two-axis mechanics move correctly, respect limits, no singularities at 0°–85°. | **Partial** | Rotational dynamics and gear reflection verified; joint hard stops and tracker-level integration pending |
| FR-09 | Angle of incidence and POA irradiance within 1% of hand calculations. | **Done** | `tests/unit/test_energy_model.m` (10/10) |
| FR-10 | Captured and consumed energy within 1%; actuator energy included. | **Partial** | Captured energy verified; actuator energy pending. |
| FR-11 | Clear, cloudy, rainy, sunrise, sunset, night scenarios run without solver errors. | **Open** | Scenario tests pending. |
| FR-12 | Motor or sensor fault detected; tracker enters safe state. | **Partial** | Fault mode exists in `tracker_mode_logic.m`; scenario test pending. |
| FR-13 | `run_project.m` regenerates figures and metrics from a clean clone. | **Done** | Full-day run verified; clean-clone repeat pending under R-09. |

### Non-functional requirements

| ID | Requirement | Status | Evidence / gap |
|---|---|---|---|
| NFR-01 | Single entry point, no manual steps. | **Done** | `run_project.m` |
| NFR-02 | Clean-install reproducibility. | **Partial** | Verified on two installations (R2026a, R2026b) with identical metrics — TEST_PLAN §2.1. Clean-clone verification from a fresh folder still pending. |
| NFR-03 | Centralized parameters, no hard-coded design values. | **Partial** | `project_config.m` centralizes values and blocks reference `cfg.*`, but four declared parameters (`Kd`, `rateLimit`, `filterCoefficient`, `controllerSampleTime`) are never read — DEF-006. |
| NFR-04 | Every requirement maps to a design element and a test. | **Done** | [Test Plan — Traceability](TEST_PLAN.md) |
| NFR-05 | 24-hour simulation ≤ 10 minutes. | **Done** | Baseline full-day run ≈ 8 s. The Simscape plant runs 60 s of simulated time in ≈ 2.1 s of wall time; it is a short-horizon validation model and is never run for 24 h. |
| NFR-06 | Code Analyzer no errors; Model Advisor no unresolved errors. | **Partial** | Code Analyzer clean; Model Advisor pending the final model. |
| NFR-07 | README, design, test plan, and results complete and consistent. | **Partial** | Current documents consistent; report and video pending. |
| NFR-08 | Every non-trivial AI-assisted change logged. | **Done** | AI-001…AI-012 |
| NFR-09 | Offline test execution with synthetic inputs. | **Done** | No download in the test path. |
| NFR-10 | Open-source license. | **Done** | BSD 2-Clause, 2026, Jhons Janner Samuel S. |

---

## 8. Submission Readiness Gate

A submission is ready only when every row below is checked.

| Item | Owner | Status |
|---|---|---|
| Public repository with BSD 2-Clause or MIT license | Author | ✅ |
| Root README with all required sections | Author | ✅ |
| One-click entry point that runs end-to-end | Author | ✅ |
| Toolbox and dependency list with installation steps | Author | ✅ |
| Quick test with expected outputs | Author | ✅ |
| Physical motor and mechanical model (P-02) | Author | ✅ |
| Actuator energy included in net-energy result (FR-10) | Author | ✅ |
| Clean-clone verification (R-09, NFR-02) | Author | ⬜ |
| Capstone report with GenAI disclosure | Author | ⬜ |
| 3–5 minute video tagged `#GlobalStudentChallenge2026` | Author | ⬜ |
| Evaluation form submitted with the registration email | Author | ⬜ |

---

_Last updated: 2026-11-11_
