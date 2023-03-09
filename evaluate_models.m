% Fit models to small noisy samples of data and compute
% the prediction errors

clear variables

addpath("yaml")
addpath("plot-utils")

rng(0)

test_dir = "tests";
test_data_dir = "data";

% Load config file with machine parameters
filename = "test_sim_config.yaml";
sim_config = yaml.loadFile(fullfile(test_dir, test_data_dir, filename), ...
    "ConvertToArray", true);

% Choose machines to make plots for
machines = ["machine_1", "machine_2", "machine_3"];
n_machines = numel(machines);

% Choose model config file
filename = "test_config_fp1.yaml";
% filename = "test_config_lin.yaml";
% filename = "test_config_fit.yaml";
% filename = "test_config_gpr.yaml";
opt_config = yaml.loadFile(fullfile(test_dir, test_data_dir, filename), ...
    "ConvertToArray", true);

% Choose where to sample points (in % of full operating range)
x_sample_range = [0 0.2];
%x_sample_range = [0.4 0.6];
%x_sample_range = [0.8 1];

% Choose limits for y-axes of plots
y_lims = struct;
y_lims.machine_1 = [20 180];
y_lims.machine_2 = [160 380];
y_lims.machine_3 = [100 600];

for i = 1:n_machines
    machine = machines{i};

    % get performance model parameters
    params = sim_config.machines.(machine).params;

    % Number of points to sample for the seed set
    n_samples = 5;

    % Measurement noise level
    sigma_M = 0.1;

    % Generate n sets of randomized training data
    n = 100;
    training_data = cell(1, n);

    for j = 1:n

        % Generate training data set
        X_sample = params.op_limits(1) + (x_sample_range(1) ...
            + rand(1, n_samples)' .* diff(x_sample_range)) .* diff(params.op_limits);
        training_data{j} = array2table( ...
            [X_sample sample_op_pts_poly(X_sample, params, sigma_M)], ...
            "VariableNames", {'Load', 'Power'}  ...
        );
    
    end

    % No. of points to sample for validation data set
    n_samples_val = 101;

    % Generate validation data set (without noise)
    X = linspace(params.op_limits(1), params.op_limits(2), n_samples_val)';
    validation_data = array2table( ...
        [X sample_op_pts_poly(X, params, 0)], ...
        "VariableNames", {'Load', 'Power'} ...
    );

    model_name = opt_config.machines.(machine).model;
    model_config = opt_config.models.(model_name);

    predictions = struct();
    predictions.y_mean = nan(n_samples_val, n_samples);

    figure(4+i); clf

    % Plot validation curve
    plot(validation_data.Load, validation_data.Power, 'Linewidth', 2); hold on

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
    
        plot(training_data{j}.Load, training_data{j}.Power, 'k+');
        plot(validation_data.Load, y_mean, '-', 'Color', [0.3 0.3 0.3 0.25]);
        predictions.y_mean(:, j) = y_mean';

    end

    xlim(params.op_limits)
    ylim(y_lims.(machine))
    xlabel('Load')
    ylabel('Power')
    grid on
    title(escape_latex_chars(machine))
    legend({'true', 'training data', 'predictions'}, 'location', 'best')
    p = get(gcf, 'Position');
    set(gcf, 'Position', [p(1:2) 420 315])

end

% To use data in Matlab's Regression Learner app use these
% data arrays
data_val = table(validation_data.Load, validation_data.Power, ...
    'VariableNames', {'Load', 'Power'});
data_est = table(training_data{1}.Load, training_data{1}.Power, ...
    'VariableNames', {'Load', 'Power'});