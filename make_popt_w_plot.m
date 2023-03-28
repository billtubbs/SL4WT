% Makes the plot of results of the otpimizer w
% hyper-parameter experiments
%

clear

results_dir = "simulations/sim_true_popt_w/results";
filename = "sims_summary.csv";

sims_summary = readtable(fullfile(results_dir, filename));

w = sims_summary.opt_params_w;

var_names = string(sims_summary.Properties.VariableNames);

%disp(var_names(startsWith(var_names, "eval"))')
eval_metric_names = [ ...
    "eval_metrics_final_model_RMSE" ...
    "eval_metrics_final_total_model_uncertainty" ...
    "eval_metrics_max_power_limit_exceedance" ...
    "eval_metrics_mean_excess_power_used" ...
    "eval_metrics_mean_excess_power_used_pct" ...
    "eval_metrics_mean_load_losses_vs_target" ...
    "eval_metrics_mean_power_limit_exceedance" ...
];
eval_metrics_summary = rows2vars(sims_summary(:, eval_metric_names));
eval_metrics_summary.Properties.VariableNames = ["Metric" string(w')];
disp(eval_metrics_summary(:, ["Metric" string(w(1:3)')]))
disp(eval_metrics_summary(:, ["Metric" string(w(4:6)')]))
disp(eval_metrics_summary(:, ["Metric" string(w(7:end)')]))


%% Make plot

figure(1); clf

semilogx(w, sims_summary.eval_metrics_mean_load_losses_vs_target, 'o-', ...
    'MarkerSize', 5);
hold on
semilogx(w, sims_summary.eval_metrics_max_power_limit_exceedance, 'o-', ...
    'MarkerSize', 5);
grid on
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("$w$ (log scale)", 'Interpreter', 'latex')
ylabel("Metric", 'Interpreter', 'latex')
labels = [ ...
    "Avg. load shortfall (kW)" ...
    "Max. power limit exceedance (kW)" ...
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

sims_summary