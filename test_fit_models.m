% Test model setup, prediction and update functions using
% the MATLAB fit and fitobject functions.
%

clear variables

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";


%% Test 'poly1' - linear model

data = struct();
data.Load = [50 100 150]';
data.Power = [35.05 70.18 104.77]';

params = struct();
params.significance = 0.1;
params.fit.fitType = 'poly1';

% Initialize model
[model, vars] = fit_model_setup(data, params);

assert(isequal(fieldnames(vars), {'significance', 'fit'}'))
assert(isequal(fieldnames(model), {'p1', 'p2'}'));
%fprintf("%g %g\n", model.p1, model.p2)
assert(isequal( ...
    round([model.p1 model.p2]', 4), ...
    [0.6972  0.2800]' ... % This should be same as in test_lin_models
));
assert(round(1 - vars.fit.gof.rsquare, 5, 'significant') == 1.9996e-05);
assert(round(1 - vars.fit.gof.adjrsquare, 5, 'significant') == 3.9992e-05);

% Test predictions with single point
x = 200;
[y_mean, y_sigma, y_int] = fit_model_predict(model, x, vars, params);

assert(round(y_mean, 4) == 139.7200);
assert(isequaln(y_sigma, nan));
assert(isequal(round(y_int, 4), [137.5938  141.8462]));


%% Test 'poly2' - quadratic model

data = struct();
data.Load = [50 100 150]';
data.Power = [35.05 70.18 104.77]';

params = struct();
params.significance = 0.1;
params.fit.fitType = 'poly2';

% Initialize model
[model, vars] = fit_model_setup(data, params);

assert(isequal(fieldnames(vars), {'significance', 'fit'}'))
assert(isequal(fieldnames(model), {'p1', 'p2', 'p3'}'));
%fprintf("%g %g\n", model.p1, model.p2)
assert(isequal( ...
    round([model.p1 model.p2 model.p3]', 6), ...
    [-0.000108  0.718800 -0.620000]' ...
));
assert(vars.fit.gof.rsquare == 1);  % Should fit perfectly
assert(isequaln(vars.fit.gof.adjrsquare, nan));

% Test predictions with single point
x = 200;
[y_mean, y_sigma, y_int] = fit_model_predict(model, x, vars, params);

assert(round(y_mean, 4) == 138.8200);
assert(isequaln(y_sigma, nan));
assert(isequaln(y_int, nan(1, 2)));


%% Test all models with config file

% Load configuration file
filepath = fullfile(test_dir, test_data_dir, "test_config_fit.yaml");
config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load initialization file
load load_opt_init.mat

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct
models = struct();
model_vars = struct();

% Test results to compare to
coeffs_chk = {
    [0.5101  20.4981]', ...
    [-0.0007  0.6101  17.1456]' ...
};

% Construct a model for machine 1 with each model type
machine = "machine_1";
training_data = config.training.data.(machine);
% TODO: Eliminate these transposes
training_data.Load = training_data.Load';
training_data.Power = training_data.Power';
assert(numel(training_data.Load) == numel(training_data.Power))
op_limits = config.machines.(machine).op_limits;

model_names = {'model_1_poly1', 'model_1_poly2', ...
    'model_1_cubicinterp', 'model_1_smoothingspline'};
for i = 1:numel(model_names)
    model_name = model_names{i};
    model_config = config.models.(model_name);

    % Run model setup script
    [model, vars] = feval( ...
        model_config.setup_script, ...
        training_data, ...
        model_config.params ...
    );

    % Check selected model variables and params
    assert(vars.significance == model_config.params.significance)
    assert(vars.fit.output.numobs == 3);
    switch model_config.params.fit.fitType
        case {'poly1', 'poly2'}
            %fprintf("%g %g\n", model.p1, model.p2)
            p_values = cellfun(@(x) model.(x), fieldnames(model));
            assert(isequal( ...
                round(p_values, 4), ...
                coeffs_chk{i} ...
            ))

        case 'smoothingspline'
            assert(isequal(round(model.p.coefs, 4), [
               -0.0000         0    0.5182   49.0462
                0.0000   -0.0005    0.5149   52.2292 
            ]))
    end

    % Save for use below
    models.(model_name) = model;
    model_vars.(model_name) = vars;

end

% Make predictions with each model
for i = 1:numel(model_names)
    model_name = model_names{i};
    model_config = config.models.(model_name);
    x = linspace(op_limits(1), op_limits(2), 101)';
    [y_mean, y_sigma, y_int] = fit_model_predict( ...
        models.(model_name), ...
        x, ...
        model_vars.(model_name), ...
        model_config.params ...
    );

    % Plot predictions and data
    figure(10+i); clf
    make_statdplot(y_mean, y_int(:, 1), y_int(:, 2), x, training_data.Power', ...
        training_data.Load', "Load", "Power")
    ylim([40 190])
    p = get(gcf, 'Position');
    set(gcf, 'Position', [p(1:2) 320 210])
    title(model_config.params.fit.fitType)

end

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

% Add one point to training data
training_data.Load = [training_data.Load; io_data(9, 1)];
training_data.Power = [training_data.Power; io_data(9, 2)];

% Now include cubic polynomial (poly3)
model_names = {'model_1_poly1', 'model_1_poly2', 'model_1_poly3', ...
    'model_1_cubicinterp', 'model_1_smoothingspline'};

% Update models and re-do predictions
for i = 1:numel(model_names)
    model_name = model_names{i};
    model_config = config.models.(model_name);

    % Run model setup script
    [model, vars] = feval( ...
        model_config.setup_script, ...
        training_data, ...
        model_config.params ...
    );
    
%     % Check vars updated
%     assert(model_vars.(machine).significance == model_config.params.significance)
    assert(vars.fit.output.numobs == 4);
%     assert(isequal( ...
%         round([models.(machine).p1 models.(machine).p2], 4), ...
%         [0.5240 19.6859] ... % This should be same as in test_lin_models
%     ));

    % Re-do predictions with model
    [y_mean, y_sigma, y_int] = fit_model_predict( ...
        model, ...
        x, ...
        vars, ...
        model_config.params ...
    );

    % Plot predictions and data
    figure(20+i); clf
    make_statdplot(y_mean, y_int(:, 1), y_int(:, 2), x, training_data.Power', ...
        training_data.Load', "Load", "Power")
    ylim([40 190])
    p = get(gcf, 'Position');
    set(gcf, 'Position', [p(1:2) 320 210])
    title(model_config.params.fit.fitType)

    % Save for use below
    models.(model_name) = model;
    model_vars.(model_name) = vars;

end

% Add one more point to training data
training_data.Load = [training_data.Load; io_data(8, 1)];
training_data.Power = [training_data.Power; io_data(8, 2)];

% Update models and re-do predictions
for i = 1:numel(model_names)
    model_name = model_names{i};
    model_config = config.models.(model_name);

    % Test update function
    [models.(model_name), model_vars.(model_name)] = ...
        fit_model_update( ...
            models.(model_name), ...
            training_data, ...
            model_vars.(model_name), ...
            model_config.params ...
        );

    % Check vars updated
    assert(model_vars.(model_name).fit.output.numobs == 5);

    % Re-do predictions with model
    [y_mean, y_sigma, y_int] = fit_model_predict( ...
        models.(model_name), ...
        x, ...
        model_vars.(model_name), ...
        model_config.params ...
    );

    % Plot predictions and data
    figure(30+i); clf
    make_statdplot(y_mean, y_int(:, 1), y_int(:, 2), x, training_data.Power', ...
        training_data.Load', "Load", "Power")
    ylim([40 190])
    p = get(gcf, 'Position');
    set(gcf, 'Position', [p(1:2) 320 210])
    title(model_config.params.fit.fitType)

end

