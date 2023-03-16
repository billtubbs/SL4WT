% This script is called by run_simulations.m at the end of the
% simulation to calculate and save performance metrics.
%
% The following variables should already be in the workspace:
% 
%  - LOData - struct containing simulation data
%  - LOModelData - struct containing simulation data for models
%  - sim_dir - name of directory where all simulations are saved
%  - sim_name - name of directory where current simulation is saved
%  - sim_out - Simulink.SimulationOutput object
%  - results_dir - name of directory where optimum results saved
%


% Load simulation data output variables
filename = "load_opt_out.mat";
load(fullfile(sim_dir, sim_name, results_dir, filename))

% Get sample times when optimizer made predictions
t_sample = LOData.Time;
[i_exists, i_sample] = ismember(t_sample, sim_out.tout);
assert(all(i_exists))

% Calculate loads and power at each sample period of optimizer
load_target = sim_out.load_target.Data(i_sample);
load_actual = sim_out.load_actual.Data(i_sample);
power_actual = sim_out.total_power.Data(i_sample);

% Load optimum power results file
filename = "min_power_load_solutions_opt50.csv";
power_opt = readtable(fullfile(results_dir, filename));

% Set up linear interpolation function
opt_load = @(load) interp1(power_opt.TotalLoadTarget, ...
    power_opt.TotalPower, load);

% Calculate ideal power consumption based on actual load
% (at steady-state points only)
power_ideal = opt_load(load_actual);

power_limit_exceedences = max(0, power_actual - opt_config.optimizer.params.PMax);
% Note: Load target is set at the beginning of each sample 
% period so actual load should be compared to the target set
% in the previous period.
load_losses_vs_target = load_target(1:end-1) - load_actual(2:end);
excess_power_used = power_actual(2:end) - power_ideal(2:end);

max_power_limit_exceedence = max(power_limit_exceedences);
mean_power_limit_exceedence = mean(power_limit_exceedences);
mean_load_losses_vs_target = mean(load_losses_vs_target);
mean_excess_power_used = mean(excess_power_used);
mean_excess_power_used_pct = 100 * mean_excess_power_used / ...
    mean(power_actual);

fprintf("Max. power limit exceedence: %.0f kW\n", ...
    max_power_limit_exceedence)
fprintf("Avg. power limit exceedence: %.0f kW\n", ...
    mean_power_limit_exceedence)
fprintf("Avg. load losses vs target: %.0f kW\n", ...
    mean_load_losses_vs_target)
fprintf("Avg. excess power used: %g kW\n", ...
    mean_excess_power_used)
fprintf("Avg. excess power used: %.1f%% (of total)\n", ...
    mean_excess_power_used_pct)