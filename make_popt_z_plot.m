% Makes the plot of results of the otpimizer z
% hyper-parameter experiments
%

clear

addpath("plot-utils")

sim_name = "sim_gpr_popt_z";
results_dir = sprintf("simulations/%s/results", sim_name);
plot_dir = "plots";
filename = "sims_summary.csv";

sims_summary = readtable(fullfile(results_dir, filename));
disp(sims_summary)

% Choose which results to show plot for
selection = startsWith(sims_summary.opt_config, "opt_config_gpr2");

% Results to drop
%to_drop = strcmp(sims_summary.opt_config(selection), "opt_config_gpr2_007.yaml");
%selection(to_drop) = false;

% Parameter values
z = sims_summary.opt_params_z(selection);

var_names = string(sims_summary.Properties.VariableNames);

%disp(var_names(startsWith(var_names, "eval"))')
eval_metric_names = [ ...
    "eval_metrics_final_model_RMSE" ...
    "eval_metrics_final_total_model_uncertainty" ...
    "eval_metrics_max_power_limit_exceedance" ...
    "eval_metrics_mean_excess_power_used" ...
    "eval_metrics_mean_excess_power_used_pct" ...
    "eval_metrics_mean_load_shortfalls_vs_target" ...
    "eval_metrics_mean_power_limit_exceedance" ...
];
eval_metrics = sims_summary(selection, eval_metric_names);
% Shorten column names
eval_metrics.Properties.VariableNames = ...
    cellfun(@(x) x(14:end), eval_metrics.Properties.VariableNames, 'UniformOutput', false);
eval_metrics.Properties.RowNames = string(z');
eval_metrics = sortrows(eval_metrics, 'RowNames');
z = double(string(eval_metrics.Properties.RowNames));
disp(eval_metrics)


%% Make plot

y_data = [
    eval_metrics.mean_load_shortfalls_vs_target ...
    eval_metrics.max_power_limit_exceedance ...
    eval_metrics.mean_excess_power_used ...
    eval_metrics.final_model_RMSE ...
];
labels = [ ...
    "Avg. load shortfall (kW)" ...
    "Max. power limit exceedance (kW)" ...
    "Avg. excess power used (kW)" ...
    "Final model RMSE (kW)"
];

figure(1); clf
for i = 1:size(y_data, 2)
    semilogx(z, y_data(:, i), 'o-', ...
        'MarkerSize', 5);
    hold on
end
grid on
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("$z$ (log scale)", 'Interpreter', 'latex')
ylabel("Metric", 'Interpreter', 'latex')

xlim(z([1 end]))
y_lims = axes_limits_with_margin(y_data, 0.2);
ylim(y_lims + [0 diff(y_lims)/2])
legend(labels, 'Interpreter', 'latex', 'location', 'north')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, ...
    'Position', [p(1:2) figsize] ...
)

% Save figure
filename = sprintf("%s_popt_z_plot.pdf", sim_name);
exportgraphics(gcf, fullfile(plot_dir, filename))
