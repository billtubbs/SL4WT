% Test GP model setup, prediction and update functions

clear variables

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";

% Load configuration file
filepath = fullfile(test_dir, test_data_dir, "opt_config.yaml");
config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load initialization file
load load_opt_init.mat

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct
models = struct();
model_vars = struct();
for machine = config.machines.names
    model_name = config.machines.(machine).model;
    training_data = config.training.data.(machine);
    assert(numel(training_data.Load) == numel(training_data.Power))
    model_config = config.models.(model_name);

    % Run model setup script
    [model, vars] = feval( ...
        model_config.setup_script, ...
        training_data, ...
        model_config.params ...
    );

    % Check seletced model variables and params
    assert(model.NumObservations == numel(training_data.Load));
    assert(strcmpi(model.KernelFunction, ...
        model_config.params.KernelFunction))
    assert(vars.significance == model_config.params.significance)

    % Save for use below
    models.(machine) = model;
    model_vars.(machine) = vars;

end

% Check some more things
model_sigmas = structfun(@(m) m.Sigma, models);
assert(isequal( ...
    round(model_sigmas, 4), ...
    [1.5544    0.6008  156.0314  156.0314  156.0314]' ...
))

% Make predictions with one model
machine = config.machines.names(1);
training_data = config.training.data.(machine);
op_limits = config.machines.(machine).op_limits;
model = config.machines.(machine).model;
model_config = config.models.(model);
x = linspace(op_limits(1), op_limits(2), 101)';
[y_mean, y_sigma, ci] = gpr_model_predict( ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config ...
);

% % Check outputs
% assert(isequal( ...
%     round(y_mean, 4), [
%    50.5256   50.6409   50.6409   50.6409   50.6409   50.6409   ...
%    50.6409   50.6409   50.6409   50.6409   50.6409 ...
% ]'))
% assert(isequal( ...
%     round(y_sigma, 4), [ ...
%     1.6089    1.6131    1.6131    1.6131    1.6131    1.6131 ...
%     1.6131    1.6131    1.6131    1.6131    1.6131 ...
% ]'))
% assert(isequal( ...
%     round(ci, 4), ...
%     [ ...
%    47.8791   53.1720
%    47.9876   53.2941
%    47.9876   53.2941
%    47.9876   53.2941
%    47.9876   53.2941
%    47.9876   53.2941
%    47.9876   53.2941
%    47.9876   53.2941
%    47.9876   53.2941
%    47.9876   53.2941
%    47.9876   53.2941 ...
%    ] ...
% ))

% Plot predictions and data
figure(1); clf
make_statplot(y_mean, ci(:, 1), ci(:, 2), x)
% Add training data points to plot
plot(training_data.Load, training_data.Power, 'k.', ...
    'MarkerSize', 10)

% More data points
io_data = [
  145.0000  101.0839
  175.0000  122.2633
  140.0000   97.6366
  205.0000  141.9694
  150.0000  104.5735
  210.0000  144.8131
  120.0000   84.4186
   75.0000   58.6758
   95.0000   69.4629
  170.0000  118.7371
];

% TODO: Test update function (trivial for GPs)
training_data = config.training.data.(machine);
training_data.Load = [training_data.Load io_data(1, 1)];
training_data.Power = [training_data.Power io_data(1, 2)];

[models.(machine), vars] = gpr_model_update(models.(machine), ...
    training_data, vars, model_config.params);

% Re-do predictions with one model
[y_mean, y_sigma, ci] = gpr_model_predict( ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config ...
);

% Plot predictions and data
figure(2); clf
make_statplot(y_mean, ci(:, 1), ci(:, 2), x)
% Add training data points to plot
plot(training_data.Load, training_data.Power, 'k.', ...
    'MarkerSize', 10)