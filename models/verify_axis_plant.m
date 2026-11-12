function verify_axis_plant()
% VERIFY_AXIS_PLANT  Check the explicit DC-motor axis plant against theory.
%
% Three independent checks, all against closed-form results:
%
%   T1  no-load steady state   w = Kt*V / (Kt*Ke + B*Ra)
%   T2  current ceiling        |i| <= currentLimit + 2 %
%   T3  speed rise time        tau = J_eq*Ra / (Kt*Ke + B*Ra)
%   T4  bus voltage ceiling    applied voltage <= Vbus for a larger command
%
% Coulomb friction is switched off for these checks so that the model stays
% linear and the closed-form comparisons are exact. Friction is exercised in
% the integrated tracker model instead.
%
% See also BUILD_AXIS_PLANT.

% AI-assisted: verification harness drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-10.

% Fail early with a readable message when Simscape is not installed, instead
% of the cryptic "There is no block named 'nesl_utility/...'" that Simulink
% raises from deep inside the model build.
installed = unique({ver().Name});
if ~any(strcmpi(installed, 'Simscape Electrical'))
    error('verify_axis_plant:MissingSimscape', ...
        ['Simscape Electrical is required for this check and was not ' ...
         'found in this MATLAB installation.\n' ...
         'Installed products: %s\n' ...
         'Install Simscape and Simscape Electrical from the Add-On ' ...
         'Explorer, then run verify_axis_plant again.\n' ...
         'Note: run_unit_tests and run_project do not need Simscape.'], ...
        strjoin(installed, ', '));
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'src', 'initialization'));
cfg = project_config();

az = cfg.actuator.azimuth;
p.Jload = cfg.tracker.panel.inertiaAboutAzimuthAxis;
p.Jmotor = 1e-5;
p.N = az.gearRatio;
p.eta = az.gearEfficiency;
p.B = az.viscousFriction;
p.Tc = 1e-6;                    % negligible, keeps the checks linear
                                % (the friction block rejects a zero value)
p.Ra = az.armatureResistance;
p.La = az.armatureInductance;
p.Kt = az.torqueConstant;
p.Ke = az.backEmfConstant;
p.Vbus = az.ratedVoltage;
p.currentLimit = az.currentLimit;
p.Ts = 1e-4;      % one tenth of the verification solver step

Jeq = p.Jload / p.N^2 + p.Jmotor;
den = p.Kt * p.Ke + p.B * p.Ra;
wSS = @(V) p.Kt * V / den;      % motor-side rad/s
tau = Jeq * p.Ra / den;

% Use a unique name for the temporary model. A fixed name collides with any
% variable or file of the same name already in the workspace or on the path,
% and Simulink then warns that the model is shadowing it, which looks like a
% project error even though the model itself is fine.
[~, token] = fileparts(tempname);
model = ['axis_plant_test_' token];
if bdIsLoaded(model)
    close_system(model, 0);
end
new_system(model);
open_system(model);

build_axis_plant(model, 'Axis', p);

add_block('simulink/Sources/Constant', [model '/Vcmd'], ...
    'Value', '0', 'Position', [20 100 60 120]);
add_block('simulink/Sources/Constant', [model '/Tdist'], ...
    'Value', '0', 'Position', [20 200 60 220]);
add_block('simulink/Sinks/To Workspace', [model '/logAngle'], ...
    'VariableName', 'angleLog', 'SaveFormat', 'Timeseries', ...
    'Position', [400 90 460 120]);
add_block('simulink/Sinks/To Workspace', [model '/logOmega'], ...
    'VariableName', 'omegaLog', 'SaveFormat', 'Timeseries', ...
    'Position', [400 140 460 170]);
add_block('simulink/Sinks/To Workspace', [model '/logCurrent'], ...
    'VariableName', 'currentLog', 'SaveFormat', 'Timeseries', ...
    'Position', [400 240 460 270]);
add_block('simulink/Sinks/To Workspace', [model '/logVoltage'], ...
    'VariableName', 'voltageLog', 'SaveFormat', 'Timeseries', ...
    'Position', [400 290 460 320]);

add_line(model, 'Vcmd/1', 'Axis/1', 'autorouting', 'on');
add_line(model, 'Tdist/1', 'Axis/2', 'autorouting', 'on');
add_line(model, 'Axis/1', 'logAngle/1', 'autorouting', 'on');
add_line(model, 'Axis/2', 'logOmega/1', 'autorouting', 'on');
add_line(model, 'Axis/3', 'logCurrent/1', 'autorouting', 'on');
add_line(model, 'Axis/4', 'logVoltage/1', 'autorouting', 'on');

set_param(model, 'StopTime', '4', 'Solver', 'ode23t', ...
    'MaxStep', '1e-3', 'RelTol', '1e-6', 'AbsTol', '1e-8', ...
    'SaveOutput', 'off');

results = struct('name', {}, 'pass', {}, 'detail', {});

% --- T1: no-load steady state ---------------------------------------------
V1 = 24;
set_param([model '/Vcmd'], 'Value', num2str(V1));
out = sim(model);
wEnd = out.omegaLog.Data(end);                 % deg/s at the load
wEndMotor = wEnd * pi / 180 * p.N;             % rad/s at the motor
wExpected = wSS(V1);
err = abs(wEndMotor - wExpected) / wExpected;
results(end + 1) = struct('name', 'T1 steady state', ...
    'pass', err < 0.02, ...
    'detail', sprintf('w = %.3f rad/s, expected %.3f rad/s (%.2f%%)', ...
    wEndMotor, wExpected, 100 * err));

% --- T2: current ceiling ---------------------------------------------------
iMax = max(abs(out.currentLog.Data));
results(end + 1) = struct('name', 'T2 current ceiling', ...
    'pass', iMax <= 1.02 * p.currentLimit, ...
    'detail', sprintf('|i|max = %.3f A, limit %.1f A', ...
    iMax, p.currentLimit));

% --- T3: rise time ---------------------------------------------------------
V3 = 0.8 * p.currentLimit * p.Ra;              % keeps i below the ceiling
set_param([model '/Vcmd'], 'Value', num2str(V3));
out = sim(model);
t = out.omegaLog.Time;
w = out.omegaLog.Data;                          % deg/s at the load
wFinal = w(end);
idx = find(abs(w) >= 0.632 * abs(wFinal), 1, 'first');
tRise = t(idx);
errTau = abs(tRise - tau) / tau;
results(end + 1) = struct('name', 'T3 rise time', ...
    'pass', errTau < 0.15, ...
    'detail', sprintf('t63 = %.3f s, expected tau = %.3f s (%.1f%%)', ...
    tRise, tau, 100 * errTau));

% --- T4: bus voltage ceiling ----------------------------------------------
% Command 30 V through a 24 V bus. The applied voltage must clamp to 24 V,
% not follow the command.
set_param([model '/Vcmd'], 'Value', num2str(1.25 * p.Vbus));
out = sim(model);
vMax = max(abs(out.voltageLog.Data));
vOk = abs(vMax - p.Vbus) < 1e-6;
iOk = max(abs(out.currentLog.Data)) <= 1.02 * p.currentLimit;
results(end + 1) = struct('name', 'T4 bus ceiling', ...
    'pass', vOk && iOk, ...
    'detail', sprintf('|v|max = %.3f V, bus %.1f V, |i|max = %.3f A', ...
    vMax, p.Vbus, max(abs(out.currentLog.Data))));

fprintf('\nAxis plant verification\n');
fprintf('%s\n', repmat('-', 1, 68));
for k = 1:numel(results)
    if results(k).pass
        verdict = 'PASS';
    else
        verdict = 'FAIL';
    end
    fprintf('%-20s %s  %s\n', results(k).name, verdict, results(k).detail);
end
fprintf('%s\n', repmat('-', 1, 68));

if ~all([results.pass])
    close_system(model, 0);
    error('verify_axis_plant:Failed', 'At least one axis plant check failed.');
end
close_system(model, 0);
fprintf('All axis plant checks passed.\n');
end
