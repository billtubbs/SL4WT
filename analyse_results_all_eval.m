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
opt_results.LR.filename = "opt_config_lin";
opt_results.GPR1.filename = "opt_config_gpr1";
opt_results.GPR2.filename = "opt_config_gpr2";
opt_results.GPR3.filename = "opt_config_gpr3";
opt_results.True.filename = "opt_config_true";

opt_names = string(fieldnames(opt_results));

% Locate optimizer filenames
opt_config_filenames = sims_summary.opt_config;

n_rows = size(sims_summary, 1);
opt_name = repmat("", n_rows, 1);
for name = opt_names'
    selection = startsWith(opt_config_filenames, opt_results.(name).filename);
    opt_name(selection) = name;
end
assert(~any(strcmp(opt_name, "")))
sims_summary = [table(opt_name) sims_summary];  %TODO: Should add this during simulation

% Check optimizer models
model_1_names = unique(sims_summary.opt_params_model_1_name);
assert(all(ismember( ...
    string(model_1_names), ...
    ["LIN_1" "GPR1_1" "GPR2_1" "GPR3_1" "TRUE_1"] ...
)))
model_2_names = unique(sims_summary.opt_params_model_2_name);
assert(all(ismember( ...
    string(model_2_names), ...
    ["LIN_2" "GPR1_2" "GPR2_2" "GPR3_2" "TRUE_2"] ...
)))
model_3_names = unique(sims_summary.opt_params_model_3_name);
assert(all(ismember( ...
    string(model_3_names), ...
    ["LIN_3" "GPR1_3" "GPR2_3" "GPR3_3" "TRUE_3"] ...
)))

% Check input sequence filenames
input_filenames = sort(string(unique(sims_summary.input_filename)));

% Check no duplicate sim results
assert(all(groupcounts(sims_summary, "sim_spec_name").GroupCount == 1))
assert(all(groupcounts(sims_summary, "opt_config").GroupCount == 1))

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
selected_vars.max_power_limit_exceedance = "Max. power limit exceedance (kW)";
selected_vars.mean_load_tracking_errors_vs_max = "Avg. load tracking error (kW)";
selected_vars.mean_excess_power_used = "Avg. excess power used (kW)";
selected_vars.final_model_RMSE = "Final model RMSE (kW)";

eval_var_names = string(fieldnames(selected_vars));
eval_col_names = compose("eval_metrics_%s", eval_var_names);
assert(all(ismember(eval_col_names, sims_summary.Properties.VariableNames)))


%% Make box plots of selected metrics


figure(1); clf

y_lims = [ ...
    -40 360
    -20 200
    -3 40
    -2 25
];
n_eval_vars = length(eval_var_names);
tiledlayout(n_eval_vars, 1)
for i = 1:n_eval_vars
    var_name = eval_var_names(i);
    col_name = eval_col_names(i);

    nexttile;

    % Prepare table of evaluation metrics results
    opt_eval_metrics = unstack( ...
        sims_summary(:, ["opt_name" "input_filename" col_name]), ...
        col_name, ...
        'opt_name' ...
    );
    
    % Select results to include
    opts_to_include = ["LR" "GPR1" "GPR2" "GPR3"];
    boxplot( ...
        opt_eval_metrics{:, opts_to_include}, ...
        opts_to_include, ...
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
annotation('rectangle',[0.05 0.05 0.95 1],'Color','w');

% Save figure
filename = sprintf("%s_all_eval_metrics_box.pdf", sim_name);
%save2pdf(fullfile(plot_dir, filename))
exportgraphics(gcf, fullfile(plot_dir, filename))