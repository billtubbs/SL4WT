% Fit models to small noisy samples of data and compute
% the prediction errors

clear variables

addpath("yaml")
addpath("plot-utils")

rng(0)

% Directories
sims_dir = "tests/simulations";
sim_name = "test_sim";
sim_spec_dir = "sim_specs";

plot_dir = "plots";
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

% Load system configuration from file
filename = "sys_config.yaml";
filespec = fullfile(sims_dir, sim_name, sim_spec_dir, filename);
sys_config = yaml.loadFile(filespec, "ConvertToArray", true);

machine_names = fieldnames(sys_config.equipment)';

% Choose machines to make plots for
m = 3;
machines = machine_names(m);
n_machines = numel(machines);

% Choose location of optimizer config
sims_dir = "simulations";  % use opt_configs from main simulations
filepath = fullfile(sims_dir, "test_sim_fit", sim_spec_dir);
filename = "opt_config.yaml";
opt_config = yaml.loadFile(fullfile(filepath, filename), ...
    "ConvertToArray", true);

% Number of points to sample for the seed set
n_samples = 5;

% Choose where to sample points (in % of full operating range)
%x_sample_range = [0 1];
x_sample_range = [0.05 0.15];
%x_sample_range = [0.4 0.6];
%x_sample_range = [0.8 1];

% Number of random experiments
n = 100;

% Choose limits for y-axes of plots
y_lims = struct;
y_lims.machine_1 = [20 180];
y_lims.machine_2 = [160 380];
y_lims.machine_3 = [100 600];

for i = 1:n_machines
    machine = machines{i};

    % Get machine configuration
    machine_config = sys_config.equipment.(machine);

    % Measurement noise level
    sigma_M = sys_config.equipment.(machine).params.sigma_M;

    % Generate n sets of randomized training data
    training_data = cell(1, n);

    for j = 1:n

        % Generate training data sets

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

    model_name = opt_config.machines.(machine).model;
    model_config = opt_config.models.(model_name);

    predictions = struct();
    predictions.y_mean = nan(n_samples_val, n_samples);


    %% Make a plot of one of the samples
    j_ex = 7;
%     while max(diff(sort(training_data{j_ex}.Load))) < 170
%         j_ex = j_ex + 1;
%     end
    fprintf("Sample plotted: %d\n", j_ex)

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

    figure(i); clf
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
    figure(4+i); clf

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

end

% To use data in Matlab's Regression Learner app use these
% data arrays
data_val = table(validation_data.Load, validation_data.Power, ...
    'VariableNames', {'Load', 'Power'});
data_est = table(training_data{1}.Load, training_data{1}.Power, ...
    'VariableNames', {'Load', 'Power'});