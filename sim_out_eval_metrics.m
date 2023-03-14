% Run this script after or as part of run_simulations.m
%
% The following variables should already be in the workspace:
% 
%  - sim_name - name of directory where simulation results saved
%  - sim_out - Simulink.SimulationOutput object
%  - results_dir - name of directory where optimum results saved
%

% Load optimum power results file
filename = "min_power_load_solutions_opt50.csv";
power_opt = readtable(fullfile(results_dir, filename));

% Set up linear interpolation function
opt_load = @(load) interp1(power_opt.TotalLoadTarget, ...
    power_opt.TotalPower, load);

% Calculate ideal power consumption based on actual load
power_ideal = opt_load(sim_out.load_actual.Data);




