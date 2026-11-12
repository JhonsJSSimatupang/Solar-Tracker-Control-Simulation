# Milestone 1 — Official Project Research

**Project:** Solar Tracker Control Simulation (MathWorks Challenge Project 249)  
**Research date:** 2026-11-09  
**Scope:** Official MathWorks and GitHub sources only. This report does not change
source code or Simulink models.

## 1. Source and evidence policy

The project brief is the MathWorks Challenge Project Hub entry for **Solar
Tracker Control Simulation**, and the program-wide participation, repository,
submission, and GenAI rules are in the Hub wiki. The linked registration and
submission forms are official MathWorks endpoints.  
[Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md) ·
[Hub wiki](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/) ·
[Submission form](https://www.mathworks.com/academia/student-challenge/mathworks-excellence-in-innovation-submission-form.html?tfa_1=Solar+Tracker+Control+Simulation&tfa_2=249)

## 2. Official project description and goals

### Requirements stated by the project brief

- Design and implement a controller for a multi-axis solar tracker that
  optimizes the panel/sun angle of incidence for energy absorption. The brief
  identifies the Simscape Multibody “Using the Worm and Gear Constraint Block —
  Solar Tracker” example as the foundation.  
  [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md) ·
  [Foundational MathWorks example](https://www.mathworks.com/help/sm/ug/using-the-worm-and-gear-constraint-block-solar-tracker.html)
- Implement at least one mechanical axis, add an appropriate motor/electrical
  model, design an axis controller, calculate an optimal target position, and
  validate the controller and motor through simulation.  
  [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)
- The brief’s axis concepts are azimuth (horizontal/east–west), elevation
  (vertical/solar altitude), and optional polar/roll compensation.  
  [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)

### Goals and impact

The stated impact goal is to maximize solar irradiance and renewable-energy
production. The project is categorized around sustainability and renewable
energy, control, modeling and simulation, and solar panels; its stated
difficulty is Bachelor/Master’s level.  
[Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)

### Advanced work (not a baseline requirement)

The brief presents a second/third axis, tracker-versus-no-tracker efficiency
analysis, sun-trajectory machine learning, storage integration, and fault
detection/recovery as **Advanced Work**. These are extensions, not evidence that
the minimum project must contain all of them.  
[Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)

## 3. Skills and official resources

### Skills to acquire

The official resource list points students to Simulink, Simscape, circuit and
power-system simulation, and control-design Onramps. The project therefore
expects practical skills in model-based simulation, physical/electrical
modeling, controller design, and solar-position/irradiance reasoning.  
[Project brief — Background Material](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)

### Resources explicitly linked by MathWorks

- Simulink and Simscape Onramps; Circuit Simulation and Power Systems
  Simulation Onramps; Control Design Onramp.  
  [Background Material](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)
- Simscape Multibody worm-and-gear tracker example.  
  [MathWorks example](https://www.mathworks.com/help/sm/ug/using-the-worm-and-gear-constraint-block-solar-tracker.html)
- Simscape Electrical documentation and the Simulink PV Array block.  
  [Simscape Electrical](https://www.mathworks.com/help/sps/index.html) ·
  [PV Array block](https://www.mathworks.com/help/sps/powersys/ref/pvarray.html)
- NREL Solar Position Algorithm and NOAA Solar Position Calculator, both
  linked by the official project brief as reference resources.  
  [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)

**Recommendation:** Use the existing dual-axis architecture in this repository
as the baseline, but preserve a demonstrable one-axis test path so the minimum
brief requirement remains independently verifiable. This is a project
interpretation, not an additional MathWorks rule. The recommendation follows
the brief’s “at least one” axis baseline and its advanced multi-axis option.  
[Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)

## 4. Submission and repository requirements

### Confirmed program requirements

1. Register intent using the form on the project description page. For a team,
   one person is the point of contact; the other members are supplied in the
   submission form.  
   [Hub wiki — How to participate](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/)
2. Create a **public GitHub repository** using an open-source BSD 2-Clause or
   MIT license.  
   [Submission Instructions — A1](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
3. Upload the MATLAB/Simulink solution, then submit the evaluation form using
   the same email address used for registration.  
   [Submission Instructions — A2–A3](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
4. Provide a clear repository and root `README.md` with description, setup,
   run steps, results, dependencies, and external tools.  
   [Repository Guidelines — B1](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
5. Provide one minimally interactive entry point (`.m`, `.mlx`, or `.mlapp`)
   that loads data, initializes models, runs the pipeline, and displays
   results; the guidance aims for one-click execution.  
   [Repository Guidelines — B2](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
6. Include a small self-contained sample dataset when input data are required,
   and document download instructions for larger data.  
   [Repository Guidelines — B3](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
7. List required toolboxes, blocksets, add-ons, and external libraries; include
   installation instructions for external executables or Python libraries.  
   [Repository Guidelines — B5](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
8. Include a quick test/demo and expected outputs; MATLAB unit tests are
   optional in the program guidance.  
   [Repository Guidelines — B6](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
9. Use relative paths, run on a clean MATLAB installation with required
   toolboxes, avoid unnecessary large files, use `.gitignore`, and commit with
   meaningful messages.  
   [Repository Guidelines — B8](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)

### Recommendations versus assumptions

- **Recommendation:** Keep `run_project.m`, `README.md`, `docs/`, `models/`,
  `src/`, `data/`, and `tests/` discoverable; this matches the official example
  layout and the repository’s existing convention.  
  [Repository Guidelines — B1](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
- **Recommendation:** Report tracking error, angle-of-incidence/irradiance,
  actuator effort, and energy comparison with reproducible figures or tables.
  The first two metrics follow the project objective; the reproducibility
  emphasis follows the repository evaluation guidance.  
  [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md) ·
  [Repository Guidelines — B6](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
- **Assumption:** The current repository’s BSD-2-Clause badge/license is
  intended to satisfy the program license choice; verify the committed
  `LICENSE` text before submission. The program itself requires BSD 2-Clause or
  MIT.  
  [Repository Guidelines — A1](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)

## 5. GenAI requirements

The official GenAI guidance permits AI as a supplement for brainstorming,
coding, and debugging, but requires the student to retain ownership and
critical thinking. AI output must be reviewed, understood, tested, and checked
against official documentation; unexplained “black boxes” are not acceptable.  
[GenAI Guidelines](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Generative-AI-Guidelines)

Non-trivial AI assistance must be acknowledged in a report or code comment, and
students should retain prompts or chat logs. Fabricated data, results, or
citations; plagiarism; and disclosure of confidential information to public AI
tools are prohibited by the guidance. Misused or unverified AI work may be
rejected and may affect rewards or academic standing.  
[GenAI Guidelines](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Generative-AI-Guidelines)

**Implication:** Continue the existing `docs/AI_USAGE_LOG.md`, identify the AI
role in this report and later deliverables, and ensure every AI-assisted result
has human review plus executable verification. This is a compliance
recommendation grounded in the official GenAI guidance and the repository’s
existing log convention.  
[GenAI Guidelines](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Generative-AI-Guidelines)

## 6. Confirmed unknowns and open decisions

The following items are **not specified in the public project brief/guidelines
reviewed for this milestone** and must not be presented as requirements:

- The public brief does not prescribe a particular motor type, controller
  tuning method, geographic site, simulation duration, irradiance dataset,
  performance threshold, or required number of axes beyond “at least one”.
  [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)
- The public guidance does not publish a numerical grading rubric or a
  guaranteed acceptance/reward decision rule; it says solutions are reviewed
  when project requirements are satisfied.  
  [Submission Instructions — C](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
- The project page links registration and submission forms, but form-specific
  fields and any confirmation-email instructions are not part of the public
  project README. Treat those as to-be-confirmed after registration.  
  [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)
- The Hub wiki says a four-month date is used after signup to check continued
  interest, but it is not mandatory and extra time may be requested; the
  project-specific confirmation email may still contain additional details.  
  [Hub wiki — How to participate](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/)

## 7. Implications for this Solar Tracker Control Simulation

1. **Keep the present dual-axis scope:** it exceeds the one-axis baseline while
   directly addressing azimuth and elevation behavior described in the brief.
   Label any third axis, machine learning, storage, and fault work as optional
   extensions.  
   [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)
2. **Make the entry path evaluator-friendly:** retain a root end-to-end script,
   relative paths, a quick test mode, expected outputs, and a dependency table.
   These map directly to the repository guidelines.  
   [Repository Guidelines](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
3. **Document toolbox boundaries:** identify Simulink, Simscape Multibody,
   Simscape Electrical, and Control System Toolbox dependencies only where the
   implementation actually uses them; the official brief links these resources
   but does not mandate every toolbox for the minimum solution.  
   [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md)
4. **Make evidence reproducible:** show target-angle generation, controller
   tracking, motor/joint response, and irradiance/energy outcomes with scripts,
   tests, and saved expected outputs. This is a recommendation, not a
   published numerical acceptance threshold.  
   [Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md) ·
   [Repository Guidelines](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines)
5. **Treat AI provenance as deliverable evidence:** keep the usage log,
   acknowledge non-trivial assistance, and ensure the authors can explain and
   reproduce the implementation.  
   [GenAI Guidelines](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Generative-AI-Guidelines)

## 8. Milestone 1 conclusion

The minimum defensible submission is a public, openly licensed repository
containing a runnable and documented MATLAB/Simulink solution that controls at
least one tracker axis, computes a sun-following target, and validates the
motor/controller system by simulation. This repository’s dual-axis plan is
compatible with that baseline; the remaining work is to preserve one-click
execution, explicit dependencies, reproducible evidence, and transparent AI
provenance.  
[Project brief](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Solar%20Tracker%20Control%20Simulation/README.md) ·
[Submission Instructions](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Submission-Instructions-%26-Project-Repository-Guidelines) ·
[GenAI Guidelines](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/wiki/Generative-AI-Guidelines)
