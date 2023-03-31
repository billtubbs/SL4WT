% Makes the plot of results of the otpimizer w
% hyper-parameter experiments
%

clear

addpath("plot-utils")

sim_name = "sim_true_popt_w";
results_dir = sprintf("simulations/%s/results", sim_name);
plot_dir = "plots";
filename = "sims_summary.csv";

sims_summary = readtable(fullfile(results_dir, filename));
disp(sims_summary)

% Choose which results to show plot for
selection = startsWith(sims_summary.opt_config, "opt_config");

% Results to drop
%to_drop = strcmp(sims_summary.opt_config(selection), "opt_config_gpr2_007.yaml");
%selection(to_drop) = false;

% Parameter values
w = sims_summary.opt_params_w(selection);

var_names = string(sims_summary.Properties.VariableNames);

disp(var_names(startsWith(var_names, "eval"))')
eval_metric_names = [ ...
    "eval_metrics_final_model_RMSE" ...
    "eval_metrics_final_total_model_uncertainty" ...
    "eval_metrics_max_power_limit_exceedance" ...
    "eval_metrics_mean_excess_power_used" ...
    "eval_metrics_mean_excess_power_used_pct" ...
    "eval_metrics_mean_load_tracking_errors_vs_max" ...
    "eval_metrics_mean_load_tracking_errors_vs_target" ...
    "eval_metrics_mean_power_limit_exceedance" ...
     "eval_metrics_num_opt_fails" ...
];
eval_metrics = sims_summary(selection, eval_metric_names);
% Shorten column names
eval_metrics.Properties.VariableNames = ...
    cellfun(@(x) x(14:end), eval_metrics.Properties.VariableNames, 'UniformOutput', false);
eval_metrics.Properties.RowNames = string(w');
disp(eval_metrics)


%% Make plot

figure(1); clf

semilogx(w, sims_summary.eval_metrics_max_power_limit_exceedance, 'o-', ...
    'MarkerSize', 5);
hold on
semilogx(w, sims_summary.eval_metrics_mean_load_tracking_errors_vs_target, 'o-', ...
    'MarkerSize', 5);
semilogx(w, sims_summary.eval_metrics_mean_excess_power_used, 'o-', ...
    'MarkerSize', 5);
grid on
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("$w$ (log scale)", 'Interpreter', 'latex')
ylabel("Metric", 'Interpreter', 'latex')
labels = [ ...
    "Max. power limit exceedance (kW)" ...
    "Avg. load tracking error (kW)" ...
    "Avg. excess power used (kW)" ...
];
xlim(w([1 end]))
legend(labels, 'Interpreter', 'latex')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, ...
    'Position', [p(1:2) figsize] ...
)

% Save figure
filename = sprintf("%s_popt_w_plot.pdf", sim_name);
exportgraphics(gcf, fullfile(plot_dir, filename))