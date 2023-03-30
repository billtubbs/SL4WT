% Analyse results of all-optimizer evaluation simulations
%

clear

addpath("plot-utils")

sim_name = "sim_all_eval";

results_dir = sprintf("simulations/%s/results", sim_name);
plot_dir = "plots";
filename = "sims_summary.csv";

sims_summary = readtable(fullfile(results_dir, filename));
fprintf("Results summary file size (%d, %d) loaded\n", size(sims_summary))
disp(sims_summary(1:5, {'Time', 'i_sim', 'sim_spec_name'}))

opt_results = struct();
opt_results.LR.filename = "opt_config_lin.yaml";
opt_results.GPR1.filename = "opt_config_gpr1.yaml";
opt_results.GPR2.filename = "opt_config_gpr2.yaml";
opt_results.GPR3.filename = "opt_config_gpr3.yaml";
opt_results.True.filename = "opt_config_true.yaml";

opt_names = string(fieldnames(opt_results));

% Check all optimizers simulated
opt_config_filenames = cellfun(@(s) opt_results.(s).filename, opt_names);
assert(all(ismember( ...
    string(unique(sims_summary.opt_config)), ...
    opt_config_filenames ...
)))

% Drop the true model from results
opt_to_drop = "True";
to_drop = opt_names == opt_to_drop;
opt_names = opt_names(~to_drop);
to_drop = opt_config_filenames == opt_results.(opt_to_drop).filename;
opt_config_filenames = opt_config_filenames(~to_drop);

% Check input sequence filenames
input_filenames = sort(string(unique(sims_summary.input_filename)));

% Check no duplicate sim results
assert(all(groupcounts(sims_summary, "sim_spec_name").GroupCount == 1))
assert(all(groupcounts(sims_summary, "opt_config").GroupCount == ...
    length(input_filenames)))

% Find evaluation metrics
eval_var_names = string(sims_summary.Properties.VariableNames( ...
    startsWith(sims_summary.Properties.VariableNames, "eval_metrics") ...
)');

% TODO: Statistic time-series plots of these vars
% selected_vars = [ ...
%     "power_limit_exceedances" ...
%     "load_shortfalls_vs_max" ...
%     "excess_power_used" ...
%     "overall_model_RMSE" ...
% ]';

selected_vars = struct();
selected_vars.max_power_limit_exceedance = "Max. power limit exceedances (kW)";
selected_vars.mean_load_shortfalls_vs_max = "Avg. load shortfall (kW)";
selected_vars.mean_excess_power_used = "Avg. excess power used (kW)";
selected_vars.final_model_RMSE = "Final model RMSE (kW)";

var_names = string(fieldnames(selected_vars));
col_names = compose("eval_metrics_%s", var_names);
assert(all(ismember(col_names, eval_var_names)))


%% Make box plots of selected metrics


figure(1); clf

y_lims = [ ...
    -40 400
    -50 150
    -5 45
    -2 20
];
n_plots = length(var_names);
tiledlayout(n_plots, 1)
for i = 1:n_plots
    var_name = var_names(i);
    col_name = col_names(i);

    nexttile;

    % Prepare data for boxplot summary
    data_col_names = replace(opt_config_filenames, ".", "_");
    plot_data = unstack( ...
        sims_summary(:, ["opt_config" "input_filename" col_name]), ...
        col_name, ...
        'opt_config' ...
    );

    boxplot( ...
        plot_data{:, data_col_names}, ...
        opt_names, ...
        'symbol', '' ...  % removes outliers (but does not scale)
    )
    ylim(y_lims(i, :))
    set(gca, 'TickLabelInterpreter', 'latex')
    ylabel("Metric", 'Interpreter', 'latex')
    title(sprintf("(%s) %s", char(96+i), selected_vars.(var_name)), ...
        'Interpreter', 'latex')
    grid on

end

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 5];
set(gcf, ...
    'Position', [p(1:2) figsize] ...
)

% Save figure
filename = sprintf("%s_all_eval_metrics_box.pdf", sim_name);
save2pdf(fullfile(plot_dir, filename))
%exportgraphics(gcf, fullfile(plot_dir, filename))