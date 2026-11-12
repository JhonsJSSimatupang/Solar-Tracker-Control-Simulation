function build_axis_plant(parentModel, blkName, p)
% BUILD_AXIS_PLANT  Add one explicit DC-motor tracker axis to a model.
%
%   BUILD_AXIS_PLANT(PARENTMODEL, BLKNAME, P) creates a subsystem named
%   BLKNAME inside PARENTMODEL that models one tracker axis from first
%   principles.
%
%   The plant is built from Simscape primitives instead of the library DC
%   Motor block so that every equation and every parameter is visible:
%
%     electrical   V = Ra*i + La*di/dt + Ke*omega
%     mechanical   J_eq*domega/dt = Kt*i - T_friction - T_dist/(eta*N)
%     gear         theta_load = theta_motor/N,  J_eq = J_load/N^2 + J_motor
%
%   The H-bridge is modelled as a voltage source whose command is clamped so
%   that the armature current cannot exceed P.currentLimit. Because
%   i = (V - Ke*omega)/Ra, the clamp is an exact voltage window
%   V in [Ke*omega - Ra*i_limit, Ke*omega + Ra*i_limit]. This reproduces a
%   torque-limited drive: the motor accelerates at constant current until the
%   back-EMF leaves room for the commanded voltage.
%
%   The ceiling is enforced by clamping the applied voltage to a window
%   around the back-EMF, and the result is then limited to the supply
%   voltage P.Vbus.
%
%   Inputs
%     V_cmd     V        commanded armature voltage, positive drives up
%     T_dist    N*m      disturbance torque at the load, positive resists
%
%   Outputs
%     angle_deg      deg      load angle
%     omega_deg_s    deg/s    load rate
%     current_A      A        armature current
%     voltage_V      V        applied armature voltage
%
%   P fields (SI units)
%     Jload, Jmotor, N, eta, B, Tc, Ra, La, Kt, Ke, Vbus, currentLimit
%
%   See also VERIFY_AXIS_PLANT, BUILD_SOLAR_TRACKER_MODEL.

% AI-assisted: plant structure, equations, and port wiring drafted with
% OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-10.

if nargin < 3
    error('build_axis_plant:NotEnoughInputs', ...
        'parentModel, blkName and the parameter struct are required.');
end

blkPath = [parentModel '/' blkName];

required = {'Jload', 'Jmotor', 'N', 'eta', 'B', 'Tc', ...
    'Ra', 'La', 'Kt', 'Ke', 'Vbus', 'currentLimit'};
missing = required(~isfield(p, required));
if ~isempty(missing)
    error('build_axis_plant:MissingParameter', ...
        'Missing plant parameters: %s', strjoin(missing, ', '));
end

Jeq = p.Jload / p.N^2 + p.Jmotor;
s = @(x) num2str(x, '%.10g');

if isfield(p, 'Ts')
    Ts = p.Ts;
else
    Ts = 0.01;
end

% The gear reduces the load torque that the motor has to carry.
distGain = 1 / (p.eta * p.N);

if getSimulinkBlockHandle(blkPath) < 0
    add_block('built-in/Subsystem', blkPath);
end

add_block('simulink/Sources/In1', [blkPath '/V_cmd'], ...
    'Position', [20 100 50 114]);
add_block('simulink/Sources/In1', [blkPath '/T_dist'], ...
    'Position', [20 420 50 434]);
add_block('simulink/Sinks/Out1', [blkPath '/angle_deg'], ...
    'Position', [1500 90 1530 104]);
add_block('simulink/Sinks/Out1', [blkPath '/omega_deg_s'], ...
    'Position', [1500 190 1530 204]);
add_block('simulink/Sinks/Out1', [blkPath '/current_A'], ...
    'Position', [1500 290 1530 304]);
add_block('simulink/Sinks/Out1', [blkPath '/voltage_V'], ...
    'Position', [1500 380 1530 394]);

% --- Current ceiling -------------------------------------------------------
% The armature current is i = (V - Ke*omega)/Ra. Requiring |i| <= i_limit is
% therefore equivalent to clamping the applied voltage to
%     V in [Ke*omega - Ra*i_limit,  Ke*omega + Ra*i_limit].
% The bounds depend only on the shaft speed, which is a state, so the clamp
% introduces no algebraic loop and the ceiling holds exactly in steady state.
add_block('simulink/Sources/Constant', [blkPath '/RaILim'], ...
    'Value', s(p.Ra * p.currentLimit), ...
    'Position', [360 330 400 350]);
add_block('simulink/Math Operations/Sum', [blkPath '/Vup'], ...
    'Inputs', '++', 'Position', [470 300 500 340]);
add_block('simulink/Math Operations/Sum', [blkPath '/Vlo'], ...
    'Inputs', '+-', 'Position', [470 360 500 400]);
add_block('simulink/Discontinuities/Saturation Dynamic', [blkPath '/Lim'], ...
    'Position', [560 150 600 210]);
add_block('simulink/Discontinuities/Saturation', [blkPath '/VbusLim'], ...
    'UpperLimit', s(p.Vbus), 'LowerLimit', s(-p.Vbus), ...
    'Position', [610 155 645 205]);

% --- Electrical domain -----------------------------------------------------
add_block('nesl_utility/Simulink-PS Converter', [blkPath '/S2PS_V'], ...
    'Position', [680 150 730 180]);
add_block('fl_lib/Electrical/Electrical Sources/Controlled Voltage Source', ...
    [blkPath '/CVS'], 'Position', [780 140 860 190]);
add_block('fl_lib/Electrical/Electrical Sensors/Current Sensor', ...
    [blkPath '/CS'], 'Position', [900 140 940 200]);
add_block('fl_lib/Electrical/Electrical Elements/Resistor', ...
    [blkPath '/Ra'], 'Position', [980 150 1020 190]);
add_block('fl_lib/Electrical/Electrical Elements/Inductor', ...
    [blkPath '/La'], 'Position', [1060 150 1100 190]);
add_block('fl_lib/Electrical/Electrical Sources/Controlled Voltage Source', ...
    [blkPath '/BEMF'], 'Position', [1140 140 1220 190]);
add_block('fl_lib/Electrical/Electrical Elements/Electrical Reference', ...
    [blkPath '/ERef'], 'Position', [1140 260 1180 300]);
set_param([blkPath '/Ra'], 'R', s(p.Ra));
set_param([blkPath '/La'], 'L', s(p.La));

% --- Electromechanical coupling -------------------------------------------
add_block('simulink/Math Operations/Gain', [blkPath '/Kt'], ...
    'Gain', s(p.Kt), 'Position', [980 380 1020 410]);
add_block('simulink/Math Operations/Gain', [blkPath '/DistReflect'], ...
    'Gain', s(distGain), 'Position', [250 420 300 450]);
add_block('simulink/Math Operations/Sum', [blkPath '/Tsum'], ...
    'Inputs', '+-', 'Position', [360 380 390 430]);

% --- Mechanical domain ----------------------------------------------------
add_block('nesl_utility/Simulink-PS Converter', [blkPath '/S2PS_T'], ...
    'Position', [450 390 500 420]);
add_block('fl_lib/Mechanical/Mechanical Sources/Ideal Torque Source', ...
    [blkPath '/T'], 'Position', [550 380 640 440]);
add_block('fl_lib/Mechanical/Rotational Elements/Inertia', ...
    [blkPath '/J'], 'Position', [700 400 740 440]);
add_block('fl_lib/Mechanical/Rotational Elements/Rotational Friction', ...
    [blkPath '/Friction'], 'Position', [700 480 740 540]);
add_block('fl_lib/Mechanical/Rotational Elements/Mechanical Rotational Reference', ...
    [blkPath '/Ref'], 'Position', [700 580 740 620]);
add_block('fl_lib/Mechanical/Mechanical Sensors/Ideal Rotational Motion Sensor', ...
    [blkPath '/S'], 'Position', [820 400 880 470]);
set_param([blkPath '/J'], 'inertia', s(Jeq));
set_param([blkPath '/Friction'], ...
    'brkwy_trq', s(p.Tc), 'visc_coef', s(p.B), ...
    'Col_trq', s(p.Tc), 'brkwy_vel', '0.01');
set_param([blkPath '/S'], 'position_port', 'true');

% --- Signal conditioning ---------------------------------------------------
add_block('nesl_utility/PS-Simulink Converter', [blkPath '/PS2S_i'], ...
    'Position', [980 240 1020 270]);
add_block('nesl_utility/PS-Simulink Converter', [blkPath '/PS2S_w'], ...
    'Position', [940 420 980 450]);
add_block('nesl_utility/PS-Simulink Converter', [blkPath '/PS2S_th'], ...
    'Position', [940 490 980 520]);
add_block('simulink/Math Operations/Gain', [blkPath '/Ke'], ...
    'Gain', s(p.Ke), 'Position', [1040 420 1080 450]);
add_block('nesl_utility/Simulink-PS Converter', [blkPath '/S2PS_e'], ...
    'Position', [1130 420 1180 450]);

% The electrical and mechanical networks are separate Simscape networks, so
% the back-EMF feedback crosses a solver boundary. In a fixed-step model with
% local solvers that path would be an algebraic loop, which is unsupported.
% A one-sample delay on the speed feedback removes the loop. The delay is
% one control step and does not change the steady-state equations.
add_block('simulink/Discrete/Unit Delay', [blkPath '/wDelay'], ...
    'SampleTime', s(Ts), 'InitialCondition', '0', ...
    'Position', [1080 480 1120 510]);
add_block('simulink/Math Operations/Gain', [blkPath '/Rad2Deg'], ...
    'Gain', '180/pi', 'Position', [1060 520 1100 550]);
add_block('simulink/Math Operations/Gain', [blkPath '/OneOverN'], ...
    'Gain', s(1 / p.N), 'Position', [1140 520 1180 550]);
add_block('simulink/Math Operations/Gain', [blkPath '/w2deg'], ...
    'Gain', '180/pi', 'Position', [1140 420 1180 450]);
add_block('simulink/Math Operations/Gain', [blkPath '/wLoad'], ...
    'Gain', s(1 / p.N), 'Position', [1220 420 1260 450]);

% --- Solvers: the electrical and mechanical networks are independent ------
add_block('nesl_utility/Solver Configuration', [blkPath '/SolverE'], ...
    'Position', [120 620 160 660]);
add_block('nesl_utility/Solver Configuration', [blkPath '/SolverM'], ...
    'Position', [900 620 940 660]);

% --- Signal wiring ---------------------------------------------------------
sig = { ...
    'V_cmd/1',      'Lim/2'
    'Vup/1',        'Lim/1'
    'Vlo/1',        'Lim/3'
    'Lim/1',        'VbusLim/1'
    'VbusLim/1',    'S2PS_V/1'
    'Ke/1',         'Vup/1'
    'Ke/1',         'Vlo/1'
    'RaILim/1',     'Vup/2'
    'RaILim/1',     'Vlo/2'
    'CS/RConn1',    'PS2S_i/LConn1'
    'PS2S_i/Out1',  'Kt/1'
    'Kt/1',         'Tsum/1'
    'T_dist/1',     'DistReflect/1'
    'DistReflect/1','Tsum/2'
    'Tsum/1',       'S2PS_T/1'
    'PS2S_w/Out1',  'wDelay/1'
    'wDelay/1',     'Ke/1'
    'Ke/1',         'S2PS_e/1'
    'PS2S_w/Out1',  'w2deg/1'
    'w2deg/1',      'wLoad/1'
    'wLoad/1',      'omega_deg_s/1'
    'PS2S_i/Out1',  'current_A/1'
    'PS2S_th/Out1', 'Rad2Deg/1'
    'Rad2Deg/1',    'OneOverN/1'
    'OneOverN/1',   'angle_deg/1'
    'VbusLim/1',    'voltage_V/1'};
for k = 1:size(sig, 1)
    add_line(blkPath, sig{k, 1}, sig{k, 2}, 'autorouting', 'on');
end

% --- Physical wiring -------------------------------------------------------
% Roles confirmed empirically: converter L1 = PS control input; the motion
% sensor has L1 = shaft, R1 = case, R2 = speed, R3 = position.
phys = { ...
    'S2PS_V/RConn1',  'CVS/RConn1'
    'S2PS_e/RConn1',  'BEMF/RConn1'
    'S2PS_T/RConn1',  'T/RConn1'
    'CVS/LConn1',     'CS/LConn1'
    'CS/RConn2',      'Ra/LConn1'
    'Ra/RConn1',      'La/LConn1'
    'La/RConn1',      'BEMF/LConn1'
    'BEMF/RConn2',    'ERef/LConn1'
    'CVS/RConn2',     'ERef/LConn1'
    'T/LConn1',       'J/LConn1'
    'Friction/LConn1','J/LConn1'
    'Friction/RConn1','Ref/LConn1'
    'T/RConn2',       'Ref/LConn1'
    'S/LConn1',       'J/LConn1'
    'S/RConn1',       'Ref/LConn1'
    'S/RConn2',       'PS2S_w/LConn1'
    'S/RConn3',       'PS2S_th/LConn1'
    'SolverE/RConn1', 'ERef/LConn1'
    'SolverM/RConn1', 'Ref/LConn1'};
for k = 1:size(phys, 1)
    try
        add_line(blkPath, phys{k, 1}, phys{k, 2}, 'autorouting', 'on');
    catch ME
        warning('build_axis_plant:Connection', ...
            'Could not connect %s -> %s: %s', phys{k, 1}, phys{k, 2}, ME.message);
    end
end
end
