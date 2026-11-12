%% SETUP_PROJECT  Load the Solar Tracker project parameters.
%
% Calls PROJECT_CONFIG and copies the resulting configuration structure to the
% base workspace so that Simulink models and scripts can use it.
%
% Usage:
%   run('src/initialization/setup_project.m')
%
% The script is also called by RUN_PROJECT.
%
% See also PROJECT_CONFIG, CONFIGURE_SDI_PREFERENCES, RUN_PROJECT.

% AI-assisted: wrapper drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

cfg = project_config();
projectRoot = cfg.paths.root;

% Make the configuration available to Simulink models and scripts.
assignin('base', 'cfg', cfg);
assignin('base', 'projectRoot', projectRoot);

% Keep the Simulation Data Inspector from archiving runs to disk, so a host
% with little free space cannot make it disable logging in the middle of a
% simulation.
configure_sdi_preferences();
