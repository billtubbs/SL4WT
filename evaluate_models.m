% Fit various models to small noisy samples of data and compute
% the prediction errors.  This is used to produce Fig. 4 in
% INDIN 2023 paper.
%

clear variables

addpath("yaml")
addpath("plot-utils")

rng(0)

% Directories
sims_dir = "tests/simulations";
sim_name = "test_sim";
sim_spec_dir = "sim_specs";
data_dir = "data";
plot_dir = "plots";
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

% Load system configuration from file
filename = "sys_config.yaml";
filename_spec = fullfile(sims_dir, sim_name, sim_spec_dir, filename);
sys_config = yaml.loadFile(filename_spec, "ConvertToArray", true);

machine_names = fieldnames(sys_config.equipment)';
n_machines = numel(machine_names);

% Choose one machine to make plots for.
m = 3;
machine = machine_names{m};

% Choose location of optimizer config
sims_dir = "simulations";  % use opt_configs from main simulations
filepath = fullfile(sims_dir, "test_sim_gpr3", sim_spec_dir);
filename = "opt_config.yaml";
opt_config = yaml.loadFile(fullfile(filepath, filename), ...
    "ConvertToArray", true);

model_name = opt_config.machines.(machine).model;
model_config = opt_config.models.(model_name);

% Get machine configuration
machine_config = sys_config.equipment.(machine);

% Choose limits for y-axes of plots
y_lims = struct;
y_lims.machine_1 = [20 180];
y_lims.machine_2 = [160 380];
y_lims.machine_3 = [100 600];
y_lims.machine_4 = [100 600];
y_lims.machine_5 = [100 600];

% Choose whether to use existing sample data set or generate
% a new one. For existing data sets (used in simulations),
% run gen_input_seqs.m to generate these.
%  1: Specify one data sample in code
%  2: Generate random data - see below for parameters
%  3: Use data sets in data directory
option = 1;

% Choose one data set for sample plot
j_ex = 2;  % use 7 or 11

switch option

    case 1  % Data used in Fig. 4

        % These data used in test_sim_gpr3
        data = [
            243.11    196.37
            265.81    206.33
            281.16    214.46
            371.71    260.62
             445.2    302.43
            484.68    325.83
            500.85     335.5
            196.05    174.55
            474.95    319.63
             479.1    322.31
            480.69    323.17
            481.95    323.79
            482.89    324.65
            483.55    324.83
            683.89    445.81
            197.28    174.97
            309.74    228.88
            752.21     480.2
            399.83    276.34
        ];
        n = 2;
        training_data = cell(1, n);

        n_samples = 3;
        training_data{1} = array2table( ...
            data(1:n_samples, :), ...  % first n samples only
            "VariableNames", ["Load" "Power"] ...
        );
        training_data{2} = array2table( ...
            data, ...  % all data
            "VariableNames", ["Load" "Power"] ...
        );

    case 2  % Generate random data

        fprintf("Generating random training data...\n")
        n_samples = 5;

        % Choose where to sample points (in % of full operating range)
        %x_sample_range = [0 1];
        x_sample_range = [0.05 0.15];
        %x_sample_range = [0.4 0.6];
        %x_sample_range = [0.8 1];
        
        % Number of random experiments
        n = 100;

        % Measurement noise level
        sigma_M = sys_config.equipment.(machine).params.sigma_M;

        % Generate n sets of randomized training data
        training_data = cell(1, n);

        % Generate n training data sets        
        for j = 1:n

            % Option 1: Uniform random distribution of load points
            X_sample = random_sample_uniform( ...
                machine_config.params.op_limits, x_sample_range, n_samples);
    
    %         % Option 2: evenly spaced linear points
    %         X_sample = machine_config.params.op_limits(1) + (x_sample_range(1) ...
    %             + linspace(0, 1, n_samples)' .* diff(x_sample_range)) ...
    %                 .* diff(machine_config.params.op_limits);
    
            % Sample from machine load-power models (with measurement noise)
            Y_sample = sample_op_pts_poly(X_sample, machine_config.params, sigma_M);
    
            training_data{j} = array2table( ...
                [X_sample Y_sample], ...
                "VariableNames", {'Load', 'Power'}  ...
            );
        
        end
        n_samples = n_samples * ones(n, 1);

    case 3

        fprintf("Loading training data from files...\n")

        % Load files from data directory
        filename_spec = sprintf("machine_%d_data_*.csv", m);
        file_info = dir(fullfile(data_dir, filename_spec));
        n = length(file_info);
        training_data = cell(1, n);

        % Load n training data sets 
        n_samples = nan(n, 1);
        for j = 1:n
            filename = file_info(j).name;
            training_data{j} = readtable(fullfile(data_dir, filename));
            n_samples(j) = size(training_data{j}, 1);
        end

    otherwise
        error("Invalid option")

end

fprintf("Number of training data sets: %d\n", n)


%% Generate validation data using true system characteristics

% No. of points to sample for validation data set
n_samples_val = 101;

% Generate validation data set (without noise)
X = linspace( ...
    machine_config.params.op_limits(1), ...
    machine_config.params.op_limits(2), ...
    n_samples_val ...
)';
validation_data = array2table( ...
    [X sample_op_pts_poly(X, machine_config.params, 0)], ...
    "VariableNames", {'Load', 'Power'} ...
);

predictions = struct();
predictions.y_mean = nan(n_samples_val, n);


%% Make a plot of one of the samples

%     while max(diff(sort(training_data{j_ex}.Load))) < 170
%         j_ex = j_ex + 1;
%     end
fprintf("Plotting example data set number %d\n", j_ex)

% Initialize and fit model
[model, vars] = builtin("feval", ...
    model_config.setupFcn, ...
    training_data{j_ex}, ...
    model_config.params ...
);

% Make predictions
[y_mean, y_sigma, ci] = builtin("feval", ...
    model_config.predictFcn, ...
    model, ...
    validation_data.Load, ...
    vars, ...
    model_config.params ...
);

figure(m); clf
x = validation_data.Load;

% Plot true system output
plot(x, validation_data.Power, 'k--', 'Linewidth', 1); 
hold on

% Make plot with confidence intervals
make_statdplot( ...
    y_mean, ...
    ci(:,2), ...
    ci(:,1), ...
    x, ...
    training_data{j_ex}.Power, ...
    training_data{j_ex}.Load, ...
    'Load (kW)', ...
    {''}, ...
    "prediction", ...
    "CI", ...
    y_lims.(machine) ...
    );
    %y_labels, line_label, area_label, y_lim)
ylabel('Power (kW)', 'Interpreter', 'latex')
xlim(machine_config.params.op_limits)
legend({'true', 'CI', 'prediction', 'data'})
title(escape_latex_chars(machine_config.name), 'Interpreter', 'latex')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, ...
    'Position', [p(1:2) figsize] ...
)
p = get(gcf, 'Position');
filename = sprintf("eval_plot_%s_m%d_single.pdf", ...
    model_config.name, m);
save2pdf(fullfile(plot_dir, filename))


%% Construct plot with all sample results

figure(4); clf

% Plot true system output
plot(validation_data.Load, validation_data.Power, 'k--', 'Linewidth', 1); 
hold on

rmses = nan(n, 1);
error_maxes = nan(n, 1);
n_exceeded = nan(n, 1);
for j = 1:n

    % Initialize model
    [model, vars] = builtin("feval", ...
        model_config.setupFcn, ...
        training_data{j}, ...
        model_config.params ...
    );

    % Make predictions
    [y_mean, y_sigma, ci] = builtin("feval", ...
        model_config.predictFcn, ...
        model, ...
        validation_data.Load, ...
        vars, ...
        model_config.params ...
    );

    % Plot colors - 4th term is the alpha transparency
    c_grey = [0.3 0.3 0.3 0.25];
    c1 = [0      0.447  0.741 0.25];
    c2 = [0.850  0.325  0.098 0.25];
    c3 = [0.929  0.694  0.125 0.25];
    plot(training_data{j}.Load, training_data{j}.Power, 'k.');
    plot(validation_data.Load, ci(:, 2), '-', 'Color', c2);
    plot(validation_data.Load, y_mean, '-', 'Color', c1);
    plot(validation_data.Load, ci(:, 1), '-', 'Color', c3);

    % Save predictions
    predictions.y_mean(:, j) = y_mean';

    % Calculate metrics
    y_true = validation_data.Power;
    rmses(j) = sqrt(mean((y_mean - y_true).^2));
    error_maxes(j) = max(abs(y_mean - y_true));
    ex_above = max(y_true - ci(:,2), 0);
    ex_below = max(ci(:,1) - y_true, 0);
    n_exceeded(j) = sum(ex_above > 0) + sum(ex_below > 0);

end

xlim(machine_config.params.op_limits)
ylim(y_lims.(machine))
xlabel('Load (kW)', 'Interpreter', 'latex')
ylabel('Power (kW)', 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
title(escape_latex_chars(machine_config.name), 'Interpreter', 'latex')
legend({'true', 'data', 'upper CIs', 'predictions', 'lower CIs'}, ...
    'location', 'northwest', 'Interpreter', 'latex')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, ...
    'Position', [p(1:2) figsize] ...
)
p = get(gcf, 'Position');
filename = sprintf("eval_plot_%s_m%d.pdf", model_config.name, m);
save2pdf(fullfile(plot_dir, filename))

% Report metrics
fprintf("Avg. RMSE: %f\n", mean(rmses))
fprintf("Max error: %f\n", max(error_maxes))
fprintf("Avg. no. of exceedences of CIs: %.1f\n", mean(n_exceeded))
fprintf("No. of times CIs exceeded: %d\n", sum(n_exceeded > 0))


%% Data for Matlab's Regression Learner app

% To use data in regressionLearner use these data arrays
data_val = table(validation_data.Load, validation_data.Power, ...
    'VariableNames', {'Load', 'Power'});
data_est = table(training_data{1}.Load, training_data{1}.Power, ...
    'VariableNames', {'Load', 'Power'});