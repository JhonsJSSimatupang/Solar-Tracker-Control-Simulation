function results = run_unit_tests()
% RUN_UNIT_TESTS  Run the unit test suite for the Solar Tracker project.
%
%   RESULTS = RUN_UNIT_TESTS() adds the source folders to the MATLAB path,
%   discovers every test in tests/unit, and runs the suite with text output.
%
%   Example:
%       results = run_unit_tests();
%       assertSuccess(results)
%
%   See also TEST_SOLAR_POSITION.

% AI-assisted: test runner drafted with OpenCode/DeepSeek.
% Reviewed and tested by Jhons on 2026-11-09.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(projectRoot, 'src')));

suite = testsuite(fullfile(projectRoot, 'tests', 'unit'));
runner = matlab.unittest.TestRunner.withTextOutput('Verbosity', 2);
results = runner.run(suite);
end
