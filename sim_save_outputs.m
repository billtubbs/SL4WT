% This script is called by run_simulations.m at the end of the
% simulation to calculate and save performance metrics.
%
% The following variables should already be in the workspace:
% 
%  - LOData - struct containing simulation data
%  - LOModelData - struct containing simulation data for models
%  - sims_dir - name of directory where all simulations are saved
%  - sim_name - name of directory where current simulation is saved
%  - sim_out - Simulink.SimulationOutput object
%  - results_dir - name of directory where optimum results saved
%

addpath("data-utils")


% Load simulation data output variables
filename = "load_opt_out.mat";
load(fullfile(results_dir, filename))

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
power_opt = readtable(fullfile("results", filename));

% Set up linear interpolation function
opt_load = @(load) interp1(power_opt.TotalLoadTarget, ...
    power_opt.TotalPower, load);

% Calculate ideal power consumption based on actual load
% (at steady-state points only)
power_ideal = opt_load(load_actual);

% Load final model predictions from csv file for each machine
model_errors = struct();
machine_names = fieldnames(opt_config.machines);
n_machines = length(machine_names);
all_sq_errors = cell(1, n_machines);
for i = 1:n_machines
    machine = machine_names{i};

    % Get time of last model update
    t_last = LOModelData.Machines.(machine).Time(end);

    % Load model predictions from simulation output file 
    % (see load_opt.m)
    filename = compose("%s_%s_preds_%.0f.csv", sim_name, machine, t_last);
    predictions = readtable(fullfile(results_dir, filename));
    X = predictions.op_interval;
    Y_pred = predictions.y_mean;

    % Calculate true values from true machine model 
    machine_params = sys_config.equipment.(machine).params;
    Y_true = sample_op_pts_poly(X, machine_params, 0);

    % Calculate model errors
    sq_errors = (Y_true - Y_pred).^2;
    model_errors.(machine).RMSE = sqrt(mean(sq_errors));
    model_errors.(machine).max = max(abs(Y_true - Y_pred));
    all_sq_errors{i} = sq_errors;
end
model_errors.RMSE_overall = sqrt(mean(cell2mat(all_sq_errors')));


%% Calculate main evaluation metrics

power_limit_exceedances = max(0, power_actual - opt_config.optimizer.params.PMax);
% Note: Load target is set at the beginning of each sample 
% period so actual load should be compared to the target set
% in the previous period.
load_losses_vs_target = load_target(1:end-1) - load_actual(2:end);
excess_power_used = power_actual(2:end) - power_ideal(2:end);

max_power_limit_exceedance = max(power_limit_exceedances);
mean_power_limit_exceedance = mean(power_limit_exceedances);
mean_load_losses_vs_target = mean(load_losses_vs_target);
mean_excess_power_used = mean(excess_power_used);
mean_excess_power_used_pct = 100 * mean_excess_power_used / ...
    mean(power_actual);
total_model_uncertainty = LOData.TotalUncertainty(end);
final_model_RMSE = model_errors.RMSE_overall;


fprintf("Max. power limit exceedance: %.0f kW\n", ...
    max_power_limit_exceedance)
fprintf("Avg. power limit exceedance: %.0f kW\n", ...
    mean_power_limit_exceedance)
fprintf("Avg. load losses vs target: %.0f kW\n", ...
    mean_load_losses_vs_target)
fprintf("Avg. excess power used: %g kW\n", ...
    mean_excess_power_used)
fprintf("Avg. excess power used: %.1f%% (of total)\n", ...
    mean_excess_power_used_pct)
fprintf("Final total model uncertainty: %.1f\n", ...
    total_model_uncertainty)
fprintf("Final overall model prediction error (RMSE): %.1f kW\n", ...
    final_model_RMSE)


%% Collect all parameters and metrics to add to summary file

% Evaluation metrics
eval_metrics = struct();
eval_metrics.max_power_limit_exceedance = max_power_limit_exceedance;
eval_metrics.mean_power_limit_exceedance = mean_power_limit_exceedance;
eval_metrics.mean_load_losses_vs_target = mean_load_losses_vs_target;
eval_metrics.mean_excess_power_used = mean_excess_power_used;
eval_metrics.mean_excess_power_used_pct = mean_excess_power_used_pct;
eval_metrics.total_model_uncertainty = total_model_uncertainty;
eval_metrics.final_model_RMSE = final_model_RMSE;
eval_metrics = objects2tablerow( ...
    containers.Map("eval_metrics", eval_metrics) ...
);

% Simulation parameters
sim_params = objects2tablerow( ...
    containers.Map("sim_params", sim_config.simulation.params) ...
);

config_files = array2table( ...
    [sim_config.system.config_filename ...
     sim_config.optimizer.config_filename], ...
    'VariableNames', ["sys_config" "opt_config"] ...
);

% Determine name of sim_spec file (depends if multiple sims being run)
if n_sim_queue > 0
    sim_spec = string(files_info(i_sim).name);
else
    sim_spec = sim_spec_filename;
end

% Inputs
input_filename = sim_config.simulation.inputs.filename;

% Optimizer parameters
opt_params = objects2tablerow( ...
    containers.Map("opt_params", opt_config.optimizer.params) ...
);

opt_fails = sum(LOData.OptFails);

% Optimizer models - this can get quite big!
opt_config_models = objects2tablerow( ...
    containers.Map("opt_params", opt_config.models) ...
);

% Combine selected results into one row
results_table = [ ...
    array2tablerow(datetime(), 'Time') ...
    table(i_sim, sim_name, sim_spec) ...
    config_files ...
    table(input_filename) ...
    sim_params ...
    opt_params ...
    table(opt_fails) ...
    opt_config_models ...
    eval_metrics ...
];

% Save summary results to csv file
filename = sim_config.simulation.outputs.summary.filename;
if isfile(fullfile(results_dir, filename))
    % Load existing results and combine
    existing_results = readtable(fullfile(results_dir, filename), ...
        'TextType','string');
    fprintf("Existing summary file: %s\n", filename)
    results_table = outerjoin(existing_results, results_table, ...
        'MergeKeys', true);
end

% Save combined results back to same csv file
writetable(results_table, fullfile(results_dir, filename));
fprintf("Summary saved to file:\n%s\n", fullfile(results_dir, filename))

%% Display evaluation metrics summary table
var_names = results_table.Properties.VariableNames( ...
    startsWith(results_table.Properties.VariableNames, "eval_metrics") ...
);
row_names = compose("Sim_%d", 1:size(results_table, 1));
eval_results = results_table(:, var_names);
var_names = cellfun(@(x) erase(x, 'eval_metrics_'), var_names, ...
    'UniformOutput', false);
eval_results.Properties.RowNames = row_names;
eval_results.Properties.VariableNames = var_names;
fprintf("\n"); disp(rows2vars(eval_results))