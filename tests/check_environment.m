function status = check_environment()
% CHECK_ENVIRONMENT  Check MATLAB version and required toolboxes.
%
%   STATUS = CHECK_ENVIRONMENT prints a table with the installation status of
%   every product required by the Solar Tracker Control Simulation. Run this
%   before starting the simulation work and record the result in
%   docs/DEVELOPMENT_LOG.md.
%
%   STATUS is a struct with the fields Required, Optional, MissingRequired,
%   and AllRequiredInstalled.

requiredProducts = [
    "MATLAB"
    "Simulink"
    "Simscape"
    "Simscape Multibody"
    "Simscape Electrical"
    "Control System Toolbox"
    "Simulink Control Design"
];

optionalProducts = [
    "Stateflow"
    "Simulink Test"
    "Simulink Coverage"
    "Optimization Toolbox"
    "Statistics and Machine Learning Toolbox"
    "Symbolic Math Toolbox"
    "Fuzzy Logic Toolbox"
    "Deep Learning Toolbox"
    "MATLAB Report Generator"
];

installed = string({ver().Name});

fprintf('\nMATLAB environment check\n');
fprintf('========================\n');
fprintf('MATLAB version : %s\n', version);
fprintf('Operating system: %s\n\n', computer);

fprintf('%-38s %-12s %s\n', 'Product', 'Type', 'Status');
fprintf('%-38s %-12s %s\n', repmat('-', 1, 38), repmat('-', 1, 12), repmat('-', 1, 12));

missingRequired = strings(0, 1);

for i = 1:numel(requiredProducts)
    product = requiredProducts(i);
    isInstalled = any(strcmpi(installed, product));
    if isInstalled
        fprintf('%-38s %-12s %s\n', product, 'Required', 'installed');
    else
        fprintf('%-38s %-12s %s\n', product, 'Required', 'MISSING');
        missingRequired(end + 1, 1) = product; %#ok<AGROW>
    end
end

for i = 1:numel(optionalProducts)
    product = optionalProducts(i);
    isInstalled = any(strcmpi(installed, product));
    if isInstalled
        fprintf('%-38s %-12s %s\n', product, 'Optional', 'installed');
    else
        fprintf('%-38s %-12s %s\n', product, 'Optional', 'not installed');
    end
end

status = struct();
status.Required = requiredProducts;
status.Optional = optionalProducts;
status.MissingRequired = missingRequired;
status.AllRequiredInstalled = isempty(missingRequired);

fprintf('\n');
if status.AllRequiredInstalled
    fprintf('All required products are installed.\n\n');
else
    fprintf('Missing required products:\n');
    for i = 1:numel(missingRequired)
        fprintf('  - %s\n', missingRequired(i));
    end
    fprintf('\nInstall them from the MathWorks installer or Add-On Manager,\n');
    fprintf('then run check_environment again.\n\n');
end
end
