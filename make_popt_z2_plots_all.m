% Makes the plot of results of the otpimizer z
% hyper-parameter experiments
%

clear

addpath("plot-utils")

sim_name = "sim_gpr_popt_z2";
results_dir = sprintf("simulations/%s/results", sim_name);
plot_dir = "plots";
filename = "sims_summary.csv";

sims_summary = readtable(fullfile(results_dir, filename));
%disp(head(sims_summary))

% Choose which results to include in plots
opt_config_names = [
    "opt_config_lin" ...
    "opt_config_gpr1" ...
    "opt_config_gpr2" ...
    "opt_config_gpr3" ...
];
opt_labels = ["LR" "GPR1" "GPR2" "GPR3"];

% Results to drop
%to_drop = strcmp(sims_summary.opt_config(selection), "opt_config_gpr2_007.yaml");
%select_rows(to_drop) = false;

% Parameter values
% z = sims_summary.opt_params_z(select_rows);

var_names = string(sims_summary.Properties.VariableNames);

%disp(var_names(startsWith(var_names, "eval"))')
col_names = [ ...
    "opt_config" ...
    "opt_params_z" ...
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
data = sims_summary(:, col_names);

% Shorten column names
%eval_metrics.Properties.VariableNames = ...
%    cellfun(@(x) x(14:end), eval_metrics.Properties.VariableNames, 'UniformOutput', false);

%eval_metrics.Properties.RowNames = string(z');
%eval_metrics = sortrows(eval_metrics, 'RowNames');
%z = double(string(eval_metrics.Properties.RowNames));
disp(data)


%% Make figure with subplots

eval_col_names = [
    "eval_metrics_max_power_limit_exceedance" ...
    "eval_metrics_mean_load_tracking_errors_vs_target" ...
    "eval_metrics_mean_excess_power_used" ...
    "eval_metrics_final_model_RMSE" ...
];
labels = [ ...
    sprintf("Max. power limit\nexceedance (kW)") ...
    sprintf("Avg. load tracking\nerror (kW)") ...
    sprintf("Avg. excess power\nused (kW)") ...
    sprintf("Final model RMSE\n(kW)")
];

figure(1); clf

tiledlayout(1, 4)

n_plots = length(eval_col_names);
for i = 1:n_plots

    nexttile
    for j = 1:length(opt_config_names)
        select_rows = startsWith(data.opt_config, opt_config_names(j));
        x = data{select_rows, 'opt_params_z'};
        y = data{select_rows, eval_col_names(i)};
        semilogx(x, y, 'o-', 'MarkerSize', 5, 'LineWidth', 1);
        hold on
    end
    xlim(x([1 end]))
    grid on
    set(gca, 'TickLabelInterpreter', 'latex')
    % Add more tick labels since Matlab seems to leave most out
    set(gca, 'xtick', 10.^[-1 3 7])
    xlabel("$z$ (log scale)", 'Interpreter', 'latex')
    ylabel(labels(i), 'Interpreter', 'latex')

    if i == 4
        legend(escape_latex_chars(opt_labels), 'Interpreter', 'latex')
    end

end

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [n_plots*2+2.5 2];
set(gcf, 'Position', [p(1:2) figsize])
filename = sprintf("%s_popt_z2_plot_%d.pdf", sim_name, n_plots);
exportgraphics(gcf, fullfile(plot_dir, filename))
