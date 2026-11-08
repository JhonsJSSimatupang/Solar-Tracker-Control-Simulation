# ⚙️ Gate G2 — Actuator Sizing Calculations

## Solar Tracker Control Simulation

> **Status:** Preliminary sizing complete (2026-11-09). The results select the
> gear ratios and verify that the preliminary motors meet the torque, current,
> and speed requirements. The dynamic model at Gate G3 confirms the values.

This note records the static worst-case sizing of the azimuth and elevation
axes. It is reproducible with:

```matlab
addpath(genpath('src'));
cfg = project_config();
sizing = design_sizing(cfg);
```

The unit tests in `tests/unit/test_design_sizing.m` lock the numerical results.

---

## 1. Purpose

The dual-axis tracker needs two actuators. The azimuth axis rotates the whole
panel assembly about a vertical axis; the elevation axis changes the panel tilt
about a horizontal axis. This calculation answers three questions:

1. What output torque must each axis produce?
2. Which gear ratio and motor torque are required?
3. Do the preliminary motors stay within the current, voltage, and speed limits?

The calculation is a static, worst-case check. It uses the design acceleration
and slew rate rather than the full trajectory, and it adds a wind torque
allowance. The Simscape model at Gate G3 replaces the static check with a
dynamic simulation.

---

## 2. Inputs and assumptions

| Symbol | Value | Unit | Source |
|---|---:|---|---|
| Panel width, `w` | 1.0 | m | `project_config.m` |
| Panel height, `h` | 1.6 | m | `project_config.m` |
| Panel area, `A` | 1.6 | m² | `w × h` |
| Panel mass, `m` | 12 | kg | `project_config.m` |
| Centre-of-mass offset, `e` | 0.05 | m | Assumed along the panel height |
| Tilt-axis inertia, `J_tilt` | 3.5 | kg·m² | Preliminary estimate |
| Azimuth-axis inertia, `J_az` | 8.0 | kg·m² | Preliminary estimate |
| Design angular acceleration, `α` | 0.05 | rad/s² | Design choice |
| Design slew rate, `ω_out` | 2.0 | °/s | Design choice |
| Design slew rate, `ω_out` | 0.03491 | rad/s | Converted |
| Friction torque per axis, `τ_f` | 1.0 | N·m | Bearing and seal estimate |
| Wind torque allowance, `τ_w` | 10.0 | N·m | Worst-case gust on a balanced panel |
| Gravity, `g` | 9.81 | m/s² | Standard |
| Azimuth gear ratio, `i_az` | 100:1 | — | Preliminary selection |
| Elevation gear ratio, `i_el` | 150:1 | — | Preliminary selection |
| Gear efficiency, `η` | 0.70 | — | Worm-gear estimate |
| Motor rated voltage | 24 | V | Preliminary selection |
| Armature resistance, `R` | 1.2 | Ω | Preliminary selection |
| Torque constant, `K_t` | 0.05 | N·m/A | Preliminary selection |
| Back-EMF constant, `K_b` | 0.05 | V·s/rad | Preliminary selection |
| Current limit, `I_lim` | 5.0 | A | Driver limit |

The inertia values include the panel, frame, mounting hardware, and bearings.
They are larger than the thin-plate geometric estimates because the frame and
hardware add mass away from the rotation axes. Section 3 quantifies the
difference.

The wind torque is a static allowance, not a gust model. It covers a
10 N·m disturbance on each axis at the same time, which is conservative for the
tracking speeds of interest.

---

## 3. Panel inertia

For a thin rectangular plate of mass `m`, width `w`, and height `h`, the
geometric inertia about the tilt axis (through the centre, parallel to the
width) is:

```text
J_tilt,geom = m h² / 12
            = 12 × 1.6² / 12
            = 2.56 kg·m²
```

About the azimuth axis (vertical through the centre):

```text
J_az,geom = m (w² + h²) / 12
          = 12 × (1.0² + 1.6²) / 12
          = 3.56 kg·m²
```

The values used in the sizing are higher:

| Axis | Geometric estimate | Used value | Ratio |
|---|---:|---:|---:|
| Tilt | 2.56 kg·m² | 3.5 kg·m² | 1.37 |
| Azimuth | 3.56 kg·m² | 8.0 kg·m² | 2.25 |

The used values are preliminary. The azimuth ratio is larger because the
azimuth joint rotates the complete assembly, including the elevation actuator,
the frame, and the mounting plate. The Simscape Multibody model at Gate G3
computes the actual inertia from the CAD-like mass distribution and replaces
these estimates.

---

## 4. Gravity torque on the elevation axis

The elevation axis is horizontal. When the panel is horizontal (tilt 0°), the
centre-of-mass offset `e` is horizontal, so gravity produces the maximum
torque:

```text
τ_g,max = m g e cos(tilt)
        = 12 × 9.81 × 0.05 × cos(0°)
        = 5.886 N·m
```

At the upper tilt limit of 85°:

```text
τ_g(85°) = 5.886 × cos(85°)
         = 0.513 N·m
```

The azimuth axis is vertical, so gravity acts parallel to the axis and
produces no torque about it. The sizing code keeps the azimuth gravity term
explicit and sets it to zero.

| Tilt | Gravity torque |
|---:|---:|
| 0° | 5.886 N·m |
| 30° | 5.097 N·m |
| 45° | 4.162 N·m |
| 60° | 2.943 N·m |
| 85° | 0.513 N·m |

The worst case for sizing is 5.886 N·m at tilt 0°.

---

## 5. Friction and wind disturbance

| Source | Azimuth | Elevation | Basis |
|---|---:|---:|---|
| Bearing and seal friction, `τ_f` | 1.0 N·m | 1.0 N·m | Constant output-side estimate |
| Wind torque allowance, `τ_w` | 10.0 N·m | 10.0 N·m | Static worst-case gust |

The friction torque is treated as a constant opposing torque. The wind torque
is added in the same direction as the motion, which is the worst case for the
actuator. In the simulation, friction is modelled with static and viscous terms
and the wind is a time-varying disturbance.

---

## 6. Required output torque

The output torque is the sum of the inertia torque, gravity torque, friction,
and wind allowance:

```text
τ_out = J α + τ_g + τ_f + τ_w
```

| Term | Azimuth | Elevation |
|---|---:|---:|
| Inertia torque, `J α` | 8.0 × 0.05 = 0.400 N·m | 3.5 × 0.05 = 0.175 N·m |
| Gravity torque, `τ_g` | 0.000 N·m | 5.886 N·m |
| Friction, `τ_f` | 1.000 N·m | 1.000 N·m |
| Wind, `τ_w` | 10.000 N·m | 10.000 N·m |
| **Required output torque** | **11.400 N·m** | **17.061 N·m** |

The elevation axis is dominated by the gravity term plus the common wind and
friction terms. The azimuth axis is dominated by the wind allowance because it
has no gravity load.

---

## 7. Gear ratio and motor torque

The motor torque is the output torque divided by the gear ratio and the gear
efficiency:

```text
τ_motor = τ_out / (i η)
```

| Axis | `τ_out` | `i` | `η` | `τ_motor` |
|---|---:|---:|---:|---:|
| Azimuth | 11.400 N·m | 100 | 0.70 | 0.16286 N·m |
| Elevation | 17.061 N·m | 150 | 0.70 | 0.16249 N·m |

Both axes require about 0.163 N·m at the motor shaft. The elevation gear ratio
is higher because the gravity load is higher; the motor torque is almost the
same on both axes. This is convenient for using the same motor model on both
axes.

The preliminary motor has a torque constant `K_t = 0.05 N·m/A`, so the required
current is:

```text
I = τ_motor / K_t
```

| Axis | Required current | Current limit | Margin |
|---|---:|---:|---:|
| Azimuth | 3.257 A | 5.0 A | 1.743 A |
| Elevation | 3.250 A | 5.0 A | 1.750 A |

Both axes use about 65% of the current limit at the worst-case design point.

---

## 8. Torque, speed, and voltage checks

### 8.1 Torque margin

At the current limit, the motor produces:

```text
τ_stall = K_t I_lim = 0.05 × 5 = 0.25 N·m
```

The maximum output torque at the current limit is:

```text
τ_out,max = τ_stall i η
```

| Axis | `τ_out,max` | `τ_out` required | Torque margin |
|---|---:|---:|---:|
| Azimuth | 0.25 × 100 × 0.70 = 17.50 N·m | 11.400 N·m | 1.535 |
| Elevation | 0.25 × 150 × 0.70 = 26.25 N·m | 17.061 N·m | 1.539 |

Both margins are greater than 1.5. The tracker can accelerate at the design
rate and reject the wind allowance without exceeding the current limit.

### 8.2 Speed margin

The motor speed at the design slew rate is:

```text
ω_motor = ω_out i
```

| Axis | `ω_out` | `i` | `ω_motor` | Motor speed | No-load speed | Speed margin |
|---|---:|---:|---:|---:|---:|---:|
| Azimuth | 0.03491 rad/s | 100 | 3.491 rad/s | 33.3 rpm | 4584 rpm | 137.5 |
| Elevation | 0.03491 rad/s | 150 | 5.236 rad/s | 50.0 rpm | 4584 rpm | 91.7 |

The no-load speed is `V_rated / K_b = 24 / 0.05 = 480 rad/s = 4584 rpm`.

The speed margin is very large. The gear ratios were selected for torque, not
speed. The motors will operate at a low duty cycle during tracking, which is
good for efficiency but means the motor is speed-oversized. A smaller, faster
motor could be selected at Gate G3 if the gearbox allows it; the current
selection is conservative and keeps the design simple.

### 8.3 Voltage margin

At the design operating point, the required armature voltage is:

```text
V_req = I R + K_b ω_motor
```

| Axis | `I R` | `K_b ω_motor` | `V_req` | Rated voltage | Margin |
|---|---:|---:|---:|---:|---:|
| Azimuth | 3.9086 V | 0.1745 V | 4.083 V | 24 V | 19.917 V |
| Elevation | 3.8997 V | 0.2618 V | 4.161 V | 24 V | 19.839 V |

The required voltage is only about 17% of the rated voltage. The controller
will use PWM to regulate the motor, so the large voltage margin is not a
problem. It does confirm that the motor can reach the design speed with the
available supply.

---

## 9. Results summary

| Quantity | Azimuth | Elevation |
|---|---:|---:|
| Inertia used | 8.0 kg·m² | 3.5 kg·m² |
| Design acceleration | 0.05 rad/s² | 0.05 rad/s² |
| Inertia torque | 0.400 N·m | 0.175 N·m |
| Gravity torque (worst case) | 0.000 N·m | 5.886 N·m |
| Friction torque | 1.000 N·m | 1.000 N·m |
| Wind allowance | 10.000 N·m | 10.000 N·m |
| **Required output torque** | **11.400 N·m** | **17.061 N·m** |
| Gear ratio | 100:1 | 150:1 |
| Gear efficiency | 0.70 | 0.70 |
| Motor torque | 0.1629 N·m | 0.1625 N·m |
| Motor current | 3.257 A | 3.250 A |
| Current limit | 5.0 A | 5.0 A |
| Current margin | 1.743 A | 1.750 A |
| Maximum output torque | 17.50 N·m | 26.25 N·m |
| Torque margin | 1.535 | 1.539 |
| Motor speed at 2°/s | 33.3 rpm | 50.0 rpm |
| No-load speed | 4584 rpm | 4584 rpm |
| Speed margin | 137.5 | 91.7 |
| Voltage required | 4.083 V | 4.161 V |
| Voltage margin | 19.917 V | 19.839 V |

All margins are positive. The preliminary design passes the static sizing
check.

---

## 10. Discussion

### 10.1 Elevation holding current and brake

The elevation axis must hold the panel against gravity when the tracker is not
moving. At tilt 0°, the holding torque is 5.886 N·m at the output, which
requires:

```text
τ_motor = 5.886 / (150 × 0.70) = 0.05606 N·m
I_hold  = 0.05606 / 0.05 = 1.121 A
P_hold  = I_hold² R = 1.121² × 1.2 = 1.508 W
```

If the motor is energized continuously at tilt 0° for 12 hours, the holding
energy is about 18.1 Wh. This is small compared with the daily panel energy
(about 1.4 kWh for a 1.6 m² panel at 18% efficiency and 5 kWh/m²/day), but it
is avoidable. A worm gear with a self-locking lead angle or a holding brake
would let the motor de-energize when the axis is stationary. The Gate G3 model
will compare the two options.

At tilt 85°, the holding current falls to 0.098 A (0.011 W), because the
gravity torque is almost zero.

### 10.2 Speed margin

The speed margin is large because the gear ratios are torque-driven. The motor
will run at 33–50 rpm at the design slew rate, while its no-load speed is
4584 rpm. This is acceptable for a preliminary design, but it suggests that a
smaller motor or a lower gear ratio could be used. The trade-off is torque
margin: reducing the gear ratio reduces the output torque at the current limit.
The current selection keeps a torque margin of about 1.5, which is a reasonable
reserve for wind gusts and model uncertainty.

### 10.3 First-order actuator energy estimate

A rough estimate of the tracking energy can be made from the sun's angular
rate and the deadband. The sun moves at 15°/h = 0.00417°/s in azimuth. With a
0.5° deadband, the azimuth axis moves 0.5° every 120 s. At 2°/s, the move
takes 0.25 s, so the duty cycle is 0.21%.

Using the friction-only torque (1.0 N·m) and ignoring the wind allowance for
this estimate:

```text
τ_motor = 1.0 / (100 × 0.70) = 0.01429 N·m
I       = 0.01429 / 0.05 = 0.2857 A
V       = 0.2857 × 1.2 + 0.05 × 3.491 = 0.5174 V
P       = 0.2857 × 0.5174 = 0.1478 W
```

Energy per move = 0.1478 W × 0.25 s = 0.037 J. With 720 moves per day (360° of
azimuth at 0.5° per move), the azimuth tracking energy is about 26.6 J
(0.007 Wh). The elevation axis makes fewer moves and consumes a similar order
of magnitude, plus the holding energy discussed above.

This estimate is deliberately rough. It ignores acceleration peaks, wind
gusts, controller losses, and driver losses. The full simulation replaces it
with an energy calculation from the voltage and current waveforms. The
important conclusion is that the actuator energy is small compared with the
captured PV energy, so the net-energy metric is dominated by the irradiance
gain.

---

## 11. Limitations and next steps

- The inertia values are preliminary estimates. The Simscape Multibody model
  computes the actual mass distribution and replaces them.
- The wind torque is a static allowance, not a gust model. The scenario tests
  will apply a time-varying wind disturbance.
- The motor parameters are representative values, not a selected commercial
  motor. The final motor and gearbox are selected at Gate G3 after the dynamic
  simulation.
- The gear efficiency is a single constant. Worm-gear efficiency varies with
  load, speed, and lead angle; the simulation uses a constant efficiency and a
  friction torque.
- The elevation holding strategy (self-locking gear versus brake) is decided at
  Gate G3.
- The static sizing does not check gear tooth strength, bearing life, or shaft
  deflection. These are mechanical design checks outside the simulation scope.

---

## 12. References

- `project_config.m` — parameter source.
- `design_sizing.m` — calculation implementation.
- `test_design_sizing.m` — numerical regression tests.
- [Simscape Multibody — Worm and Gear Constraint, Solar Tracker](https://www.mathworks.com/help/sm/ug/using-the-worm-and-gear-constraint-block-solar-tracker.html)
- [DC Motor documentation](https://www.mathworks.com/help/sps/ref/dcmotor.html)
- [Simscape Electrical — Motor and Driver Blocks](https://www.mathworks.com/help/sps/)

---

<p align="center">
  <i>Sizing is a check, not a substitute for the dynamic simulation.</i>
</p>
