# 🧰 Environment Setup

## Solar Tracker Control Simulation

> This document is the Gate G0 checklist. Complete it before starting the modeling and simulation work.

---

## 1. Current Environment

Recorded on **November 9, 2026**:

| Item | Value |
|---|---|
| MATLAB | R2026a Update 4 (26.1.0.3312084) |
| Operating system | Windows 11 Home Single Language (Build 26200) |
| Installed products | MATLAB, Simulink, Stateflow, Fuzzy Logic Toolbox, MATLAB MCP Server Toolbox |
| Missing required products | Simscape, Simscape Multibody, Simscape Electrical, Control System Toolbox, Simulink Control Design |

The unit tests for solar position, target angles, and axis comparison run with
the installed products. Simulink/Simscape model work is blocked until the
missing products are installed.

Run `tests/check_environment.m` to refresh this information.

---

## 2. Hardware and Operating System

| Item | Minimum | Recommended |
|---|---|---|
| RAM | 8 GB | 16 GB or more |
| Free disk space | 20 GB | 30 GB or more |
| CPU | Dual-core | Quad-core or more |
| GPU | Not required | Not required |
| OS | Windows 10/11, macOS, Linux | Windows 11 (current machine) |

Simscape Multibody simulations can be memory-intensive. Close other applications during long simulations.

---

## 3. MathWorks Account and License

1. Create or sign in to a MathWorks account using the campus email address.
2. Confirm that the account is linked to the campus license (Universitas Brawijaya).
3. Check the license from MATLAB:

```matlab
license('test', 'Simscape')
license('test', 'SimMechanics')          % Simscape Multibody
license('test', 'Power_System_Blocks')   % Specialized Power Systems (Simscape Electrical)
license('test', 'Control_Toolbox')
license('test', 'Simulink_Control_Design')
```

A value of `1` means the feature is available on the license.

> If a required feature is not available, contact the campus license administrator before installing. Do not purchase a personal license unless necessary.

---

## 4. Required Products

| Product | Purpose | Typical license feature |
|---|---|---|
| MATLAB | Numerical computing, scripts, analysis | `MATLAB` |
| Simulink | Block-diagram modeling and simulation | `Simulink` |
| Simscape | Physical modeling foundation | `Simscape` |
| Simscape Multibody | Mechanical tracker model | `SimMechanics` |
| Simscape Electrical | Motor and electrical model | `Power_System_Blocks` |
| Control System Toolbox | PID design and analysis | `Control_Toolbox` |
| Simulink Control Design | Controller tuning and linear analysis | `Simulink_Control_Design` |

All seven products are required for the project.

---

## 5. Optional Products

| Product | Use |
|---|---|
| Stateflow | Operating modes (day, night, cloudy, fault) |
| Simulink Test | Formal test harnesses and test sequences |
| Simulink Coverage | Model coverage analysis |
| Optimization Toolbox | Parameter optimization |
| Statistics and Machine Learning Toolbox | Data analysis and ML |
| Symbolic Math Toolbox | Equation derivation and verification |
| Fuzzy Logic Toolbox | Fuzzy controller comparison |
| Deep Learning Toolbox | Machine-learning tracker (advanced work) |
| MATLAB Report Generator | Automated report generation |

Install optional products only when the related work starts. Do not install everything at once unless disk space is sufficient.

---

## 6. Installation Steps

1. Close MATLAB.
2. Sign in to the MathWorks account at <https://www.mathworks.com>.
3. Open the R2026a installer, or use **Home → Add-Ons → Get Add-Ons** in MATLAB.
4. Choose the option to **add products to an existing installation**.
5. Select the R2026a installation folder (typically `C:\Program Files\MATLAB\R2026a`).
6. Select the required products listed in Section 4.
7. Start the installation and wait for it to finish.
8. Restart MATLAB.
9. Run the environment check (Section 7).
10. Record the result in `docs/DEVELOPMENT_LOG.md`.

> Simulink modeling must be done in the MATLAB desktop. The VS Code MATLAB extension is useful for editing `.m` files, but it does not replace the Simulink editor.

---

## 7. Verification

From the repository root:

```matlab
addpath('tests');
check_environment
```

Expected result: every required product shows `installed` and the script prints:

```text
All required products are installed.
```

If a product is still missing, recheck the installer selection and the license.

---

## 8. Development Tools

| Tool | Purpose | Status |
|---|---|---|
| MATLAB R2026a | Main development environment | Installed |
| Simulink | Model-based design | Installed |
| Git | Version control | Verify with `git --version` |
| GitHub account | Repository hosting | Verify access to the project repository |
| Visual Studio Code | Code editing | Installed |
| MATLAB extension for VS Code | Run and edit MATLAB code | Install from the VS Code marketplace |
| Web browser | NOAA, NREL, NASA POWER, BMKG | Available |

---

## 9. Data and References

Bookmark and verify access to:

- [NOAA Solar Calculator](https://gml.noaa.gov/grad/solcalc/azel.html) — reference solar position.
- [NREL Solar Position Algorithm](https://midcdmz.nrel.gov/spa/) — reference algorithm.
- [NASA POWER](https://power.larc.nasa.gov/) — irradiance and weather data.
- [BMKG](https://www.bmkg.go.id/) — Indonesian weather data.

Store a small sample dataset in `data/sample/` so tests can run offline.

---

## 10. Gate G0 Checklist

- [ ] MathWorks account linked to the campus license.
- [ ] All required products installed.
- [ ] `check_environment` reports `All required products are installed`.
- [ ] MATLAB version and toolbox list recorded in `docs/DEVELOPMENT_LOG.md`.
- [ ] Git and GitHub access verified.
- [ ] VS Code MATLAB extension installed (optional but recommended).
- [ ] Reference websites accessible.
- [ ] Team roles assigned.

---

## 11. Troubleshooting

| Problem | Solution |
|---|---|
| Toolbox is licensed but not listed in the installer | Sign out and sign in again; refresh the license; restart the installer |
| Toolbox is not licensed | Contact the campus license administrator |
| Installation fails due to disk space | Free at least 20 GB and retry |
| MATLAB does not see a newly installed toolbox | Restart MATLAB and run `rehash toolboxcache` |
| Simulink model runs slowly | Close other applications; reduce model complexity; use a fixed-step solver |
| VS Code cannot find MATLAB | Set the MATLAB installation path in the extension settings |

---

<p align="center">
  <i>A reproducible environment is the first deliverable.</i>
</p>
