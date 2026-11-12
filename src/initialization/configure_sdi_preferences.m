function configure_sdi_preferences()
%% CONFIGURE_SDI_PREFERENCES  Keep the Simulation Data Inspector off the disk.
%
% The simulations in this project read their results from the returned
% SimulationOutput. The copy that the Simulation Data Inspector (SDI) keeps is
% never used, but it is still written under the MATLAB preferences folder. On a
% host with little free disk space, SDI reacts by deleting runs and then by
% turning off recording of all data mid-run. The simulation then fails with a
% missing dataset element instead of failing on the quantity being measured,
% which is a confusing and misleading error.
%
% Disabling auto-archive and setting the archive run limit to zero keeps SDI
% from managing runs on disk at all.
%
% These settings are user preferences. The calls are wrapped in try/catch so
% the function never breaks a run on an installation where a preference does
% not exist. A guard on EXIST would not work here: these are package methods,
% and EXIST reports 0 for them even when the call is valid.
%
% Usage:
%   configure_sdi_preferences()
%
% See also SETUP_PROJECT, RUN_ALL_TESTS.

% AI-assisted: drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-12.

local_set_preference('Simulink.sdi.setAutoArchiveMode', false);
local_set_preference('Simulink.sdi.setArchiveRunLimit', 0);
end

function local_set_preference(name, value)
try
    feval(name, value);
catch
    % A preference that cannot be set is not a simulation error.
end
end
