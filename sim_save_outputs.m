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
%  - sim_spec - struct containing all simulation setup information
%

addpath("data-utils")

% Load simulation data output variables
% TODO: Add sim_name here
filename = sprintf("load_opt_out.mat", sim_name);
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
filename = sim_spec.simulation.outputs.min_power_data;
power_opt_table = readtable(fullfile("results", filename));

% Set up linear interpolation function
power_opt_func = @(load) interp1(power_opt_table.TotalLoadTarget, ...
    power_opt_table.TotalPower, load);

% Find maximum load at power limit
PMax = opt_config.optimizer.params.PMax;
max_load = fzero(@(x) power_opt_func(x) - PMax, 2500);

% Calculate ideal power consumption based on actual load
% (at steady-state points only)
power_ideal = power_opt_func(load_actual);

% Load model predictions from csv file for each machine
% and calculate prediction errors for every time sample
% (not only when models were updated)
t_sim = LOData.Time;
nT = length(t_sim);
machine_names = string(fieldnames(opt_config.machines));
n_machines = length(machine_names);

sq_errors = struct();
model_errors = struct();
for machine = machine_names'
    model_errors.(machine).RMSE = nan(size(t_sim));
    model_errors.(machine).max = nan(size(t_sim));
end
model_errors.overall_RMSE = nan(size(t_sim));
all_sq_errors = cell(1, n_machines);

for k = 1:nT

    t = t_sim(k);

    for i = 1:n_machines
        machine = machine_names{i};

        t_model = LOModelData.Machines.(machine).Time;

        if ismember(t, [0; t_model])
            % Load model predictions from simulation output file 
            % (see load_opt.m)
            filename = compose("%s_%s_preds_%.0f.csv", sim_name, machine, t);
            predictions = readtable(fullfile(results_dir, filename));
            X = predictions.op_interval;
            Y_pred = predictions.y_mean;

            % Calculate true values from true machine model 
            machine_params = sys_config.equipment.(machine).params;
            Y_true = sample_op_pts_poly(X, machine_params, 0);

            % Calculate model errors
            sq_errors.(machine) = (Y_true - Y_pred).^2;
            model_errors.(machine).RMSE(k) = sqrt(mean(sq_errors.(machine)));
            model_errors.(machine).max(k) = max(abs(Y_true - Y_pred));
        else
            model_errors.(machine).RMSE(k) = ...
                model_errors.(machine).RMSE(k - 1);
            model_errors.(machine).max(k) = ...
                model_errors.(machine).max(k - 1);
        end
        all_sq_errors{i} = sq_errors.(machine);
    end
    model_errors.overall_RMSE(k) = sqrt(mean(cell2mat(all_sq_errors')));

end


%% Calculate main evaluation metrics

power_limit_exceedances = max(0, power_actual(2:end) - opt_config.optimizer.params.PMax);
% Note: Load target is set at the beginning of each sample 
% period so actual load should be compared to the target set
% in the previous period.
load_tracking_errors_vs_target = ...
    sqrt((load_target(1:end-1) - load_actual(2:end)) .^ 2);
load_tracking_errors_vs_max = ...
    sqrt((min(load_target(1:end-1), max_load) - load_actual(2:end)) .^ 2);
excess_power_used = power_actual(2:end) - power_ideal(2:end);
total_model_uncertainty = LOData.TotalUncertainty(2:end);
overall_model_RMSE = model_errors.overall_RMSE(2:end);
num_opt_fails = LOData.OptFails(1:end-1);
opt_sol_found = num_opt_fails < opt_config.optimizer.params.n_searches;

t = LOData.Time(2:end);
metrics_summary = table( ...
    t, ...
    power_limit_exceedances, ...
    load_tracking_errors_vs_target, ...
    load_tracking_errors_vs_max, ...
    excess_power_used, ...
    total_model_uncertainty, ...
    overall_model_RMSE, ...
    num_opt_fails, ...
    opt_sol_found ...
);

% Save simulation metrics to csv file - one for each simulation
% if multiple simulations being run
filename = sprintf("%s_metrics_%03d.csv", sim_name, i_sim);
writetable(metrics_summary, fullfile(results_dir, filename))

max_power_limit_exceedance = max(power_limit_exceedances);
mean_power_limit_exceedance = mean(power_limit_exceedances);
mean_load_tracking_errors_vs_target = mean(load_tracking_errors_vs_target);
mean_load_tracking_errors_vs_max = mean(load_tracking_errors_vs_max);
mean_excess_power_used = mean(excess_power_used);
mean_excess_power_used_pct = 100 * mean_excess_power_used / ...
    mean(power_actual);
final_total_model_uncertainty = total_model_uncertainty(end);
final_model_RMSE = overall_model_RMSE(end);
num_times_opt_sol_not_found = sum(~opt_sol_found);


fprintf("Max. power limit exceedance: %.0f kW\n", ...
    max_power_limit_exceedance)
fprintf("Avg. power limit exceedance: %.0f kW\n", ...
    mean_power_limit_exceedance)
fprintf("Avg. load tracking errors vs. target: %.0f kW\n", ...
    mean_load_tracking_errors_vs_target)
fprintf("Avg. load tracking errors vs. max.: %.0f kW\n", ...
    mean_load_tracking_errors_vs_max)
fprintf("Avg. excess power used: %g kW\n", ...
    mean_excess_power_used)
fprintf("Avg. excess power used: %.1f%% (of total)\n", ...
    mean_excess_power_used_pct)
fprintf("Final total model uncertainty: %.1f\n", ...
    final_total_model_uncertainty)
fprintf("Final overall model prediction error (RMSE): %.1f kW\n", ...
    final_model_RMSE)
fprintf("Number of times optimizer failed: %d\n", ...
    num_times_opt_sol_not_found)


%% Collect all parameters and metrics to add to summary file

% Evaluation metrics
eval_metrics = struct();
eval_metrics.max_power_limit_exceedance = max_power_limit_exceedance;
eval_metrics.mean_power_limit_exceedance = mean_power_limit_exceedance;
eval_metrics.mean_load_tracking_errors_vs_target = mean_load_tracking_errors_vs_target;
eval_metrics.mean_load_tracking_errors_vs_max = mean_load_tracking_errors_vs_max;
eval_metrics.mean_excess_power_used = mean_excess_power_used;
eval_metrics.mean_excess_power_used_pct = mean_excess_power_used_pct;
eval_metrics.final_total_model_uncertainty = final_total_model_uncertainty;
eval_metrics.final_model_RMSE = final_model_RMSE;
eval_metrics.num_opt_fails = num_times_opt_sol_not_found;
eval_metrics = objects2tablerow( ...
    containers.Map("eval_metrics", eval_metrics) ...
);

% Simulation parameters
sim_params = objects2tablerow( ...
    containers.Map("sim_params", sim_spec.simulation.params) ...
);

% Config filenames
config_files = array2table( ...
    [sim_spec.system.config_filename ...
     sim_spec.optimizer.config_filename], ...
    'VariableNames', ["sys_config" "opt_config"] ...
);

% Determine name of sim_spec file (depends if multiple sims being run)
if n_sim_queue > 0
    sim_spec_name = string(files_info(i_sim).name);
else
    sim_spec_name = sim_spec_filename;
end

% Inputs
input_filename = sim_spec.simulation.inputs.filename;

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
    table(i_sim, sim_name, sim_spec_name) ...
    config_files ...
    table(input_filename) ...
    sim_params ...
    opt_params ...
    table(opt_fails) ...
    opt_config_models ...
    eval_metrics ...
];

% Save summary results to csv file
filename = sim_spec.simulation.outputs.summary.filename;
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