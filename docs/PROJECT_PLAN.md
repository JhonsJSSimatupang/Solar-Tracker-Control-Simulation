# 📋 Project Plan

## Solar Tracker Control Simulation

---

## 1. Project Overview

Solar Tracker Control Simulation is a Capstone Project focused on the study, design, development, and simulation of a solar tracking system using MATLAB and Simulink.

This document outlines the initial direction, objectives, and planned development stages of the project.

The plan will evolve as the project progresses, particularly when system requirements, technical decisions, and implementation approaches have been established.

---

## 2. Project Information

| Item | Details |
|---|---|
| Project Name | Solar Tracker Control Simulation |
| Project Type | Capstone Project |
| Project ID | 249 |
| Development Platform | MATLAB & Simulink |
| Related Program | MathWorks Excellence in Innovation |
| Current Stage | Gate G3 — baseline Simulink model and tracking metrics complete; Simscape plant pending |

---

## 3. Project Objectives

The project aims to:

- Understand the fundamental concepts of solar tracking systems.
- Explore relevant research and existing solar tracking approaches.
- Identify system requirements and project limitations.
- Develop a suitable system design.
- Build a simulation model using MATLAB and Simulink.
- Evaluate system behavior through simulation.
- Document the development process and final findings.

---

## 4. Development Roadmap

### Stage 1 — Project Preparation

- [x] Establish the GitHub repository.
- [x] Organize the initial directory structure.
- [x] Prepare the main project documentation.
- [x] Define the initial project scope.
- [x] Identify expected project deliverables.

### Stage 2 — Literature Study

- [x] Study solar energy fundamentals.
- [x] Understand solar tracking principles.
- [x] Explore different solar tracking configurations.
- [x] Review relevant control system concepts.
- [x] Collect related research papers and references.

### Stage 3 — System Design

- [x] Define system requirements.
- [x] Determine the proposed system configuration: dual-axis azimuth–elevation.
- [x] Develop the initial system architecture.
- [x] Determine the control approach: two PID loops.
- [x] Establish the simulation methodology.

### Stage 4 — Development

- [x] Prepare the MATLAB development environment.
- [x] Develop the required MATLAB scripts for solar position, target angles, and axis analysis.
- [x] Implement the clear-sky irradiance and daily energy model.
- [x] Implement the supervisory mode, deadband, and fault-safe logic.
- [x] Create the baseline Simulink model and one-click run pipeline.
- [ ] Implement the proposed Simscape plant and actuator model.
- [ ] Integrate the system components.

### Stage 5 — Simulation & Testing

- [ ] Perform initial simulations.
- [ ] Examine system responses.
- [ ] Test the system under selected conditions.
- [ ] Record simulation outputs.
- [ ] Identify potential issues.

### Stage 6 — Performance Evaluation

- [ ] Analyze simulation results.
- [ ] Evaluate system performance.
- [ ] Compare relevant system configurations if applicable.
- [ ] Identify limitations.
- [ ] Determine possible improvements.

### Stage 7 — Finalization

- [ ] Finalize MATLAB source code.
- [ ] Finalize Simulink models.
- [ ] Organize simulation results.
- [ ] Complete project documentation.
- [ ] Prepare the final Capstone report.

---

## 5. Expected Deliverables

The expected project deliverables include:

- MATLAB source code and scripts.
- Simulink system models.
- Simulation data and outputs.
- System performance analysis.
- Technical documentation.
- Final Capstone report.

The exact deliverables will be refined according to the approved project scope and requirements.

---

## 6. Dated Schedule to Submission

The submission deadline is **Friday, 5 March 2027**. The schedule below starts
on **Monday, 9 November 2026** and runs in 17 weekly blocks. Each block has one
primary outcome and an explicit exit check. Weeks marked *buffer* absorb
supervisor feedback, MATLAB product issues, or illness.

| Week | Dates | Primary outcome | Exit check |
|---:|---|---|---|
| 1 | 2026-11-09 → 11-15 | Requirements baseline and official-source audit | This checklist approved; Gate G1 signed off |
| 2 | 2026-11-16 → 11-22 | Simscape Multibody two-axis gimbal | Both joints move in the correct direction and respect limits |
| 3 | 2026-11-23 → 11-29 | Simscape Electrical DC motor and H-bridge per axis | Motor speed and torque follow the motor equations; current limited |
| 4 | 2026-11-30 → 12-06 | Integrate motor, gear, and gimbal into the main model | Torque produced by the motor drives the joint model |
| 5 | 2026-12-07 → 12-13 | Tune both PID loops on the physical plant | FR-04 and FR-05 step tests pass |
| 6 | 2026-12-14 → 12-20 | Full-day tracking on the Simscape plant | FR-06 re-verified; tracking metrics regenerated |
| 7 | 2026-12-21 → 12-27 | Actuator energy into the net-energy metric | FR-10 passes; net-energy table produced |
| 8 | 2026-12-28 → 2027-01-03 | Scenario tests: clear, cloudy, rainy, night | FR-11 passes without solver errors |
| 9 | 2027-01-04 → 01-10 | Fault detection and safe state | FR-12 scenario test passes |
| 10 | 2027-01-11 → 01-17 | Model and integration test suite | NFR-06 Model Advisor clean; tests automated |
| 11 | 2027-01-18 → 01-24 | Results consolidation and report figures | Every figure regenerated from committed scripts |
| 12 | 2027-01-25 → 01-31 | Capstone report draft, chapters 1–3 | Introduction, background, and design reviewed |
| 13 | 2027-02-01 → 02-07 | Capstone report draft, chapters 4–6 | Implementation, results, and conclusion reviewed |
| 14 | 2027-02-08 → 02-14 | Video script and screen recording | 3–5 minute cut with narration and subtitles |
| 15 | 2027-02-15 → 02-21 | *Buffer* — supervisor feedback and fixes | All reviewer comments closed |
| 16 | 2027-02-22 → 02-28 | Final verification on a clean clone | R-09 and NFR-02 pass; README metrics refreshed |
| 17 | 2027-03-01 → 03-05 | Submission | Repository public, video uploaded and tagged, form submitted |

### Milestones

| Milestone | Target date | Definition of done |
|---|---|---|
| Gate G1 — requirements baseline | 2026-11-15 | Requirements checklist approved |
| Gate G2 — actuator sizing confirmed | 2026-12-06 | Dynamic model confirms the static sizing |
| Gate G3 — integrated model | 2026-12-20 | Full-day simulation on the Simscape plant |
| Gate G4 — verification complete | 2027-01-17 | All FR/NFR have evidence |
| Draft report complete | 2027-02-07 | Full report circulated for review |
| Submission ready | 2027-02-28 | Clean-clone run reproduces every result |
| **Submission deadline** | **2027-03-05** | Video uploaded and evaluation form submitted |

### Schedule rules

- A week is only complete when its exit check passes; unfinished work moves to
  the next week and is recorded in the development log.
- Week 15 is deliberately empty. It is the only slack before the deadline.
- The report and video are scheduled before the last two weeks so that
  submission week contains no new technical work.

---

## 7. Project Resources

Relevant resources will be collected and documented throughout the project, including:

- Research papers and academic publications.
- MATLAB and Simulink documentation.
- Solar tracking references.
- Control system references.
- Supporting datasets and technical materials.

---

## 8. Planning Notes

This document represents the initial project plan.

The roadmap is subject to change based on literature findings, project requirements, technical feasibility, implementation progress, and supervisor feedback.

Technical specifications and system architecture will be documented after the corresponding decisions have been made.

---

## 9. Current Focus

Week 1 of the dated schedule: close Gate G1 by reviewing
[Requirements Checklist](REQUIREMENTS_CHECKLIST.md) and the dual-axis
requirements baseline.

The explicit DC-motor axis plant is built and verified against closed-form
results (`models/build_axis_plant.m`, `models/verify_axis_plant.m`). The next
technical block is week 4 of the schedule: insert the plant into
`models/solar_tracker.slx`, retune both loops on the physical plant, then
connect the logged voltage and current to the net-energy metric (week 7).

_Last updated: 2026-11-10_
