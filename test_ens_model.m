% Test model setup, prediction and update functions for
% the ensemble model.
%

clear variables

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";


%% Test initialization with data

data = struct();
data.Load = [50 100 150]';
data.Power = [35.05 70.18 104.77]';

model_1 = struct;
model_1.setup_script = "lin_model_setup";
model_1.predict_script = "lin_model_predict";
model_1.update_script = "lin_model_update";
model_1.params.significance = 0.1;

model_2 = struct;
model_2.setup_script = "fit_model_setup";
model_2.predict_script = "fit_model_predict";
model_2.update_script = "fit_model_update";
model_2.params.significance = 0.1;
model_2.params.fit.fitType = 'poly2';

model_3 = struct;
model_3.setup_script = "fp1_model_setup";
model_3.predict_script = "fp1_model_predict";
model_3.update_script = "fp1_model_update";
model_3.params.prior.se_sigma = 1;
model_3.params.prior.specific_energy = 0.7;
model_3.params.prior.se_int = [0.5 0.9];
model_3.params.significance = 0.1;

model_4 = struct;
model_4.setup_script = "gpr_model_setup";
model_4.predict_script = "gpr_model_predict";
model_4.update_script = "gpr_model_update";
model_4.params.fit.KernelFunction = "squaredexponential";
model_4.params.fit.KernelParameters = [15.0, 95.7708];
model_4.params.significance = 0.1;

params = struct;
params.models.model_1 = model_1;
params.models.model_2 = model_2;
params.models.model_3 = model_3;
params.models.model_4 = model_4;

% Initialize ensemble model
[models, vars] = ens_model_setup(data, params);

assert(isequal(fieldnames(models), ...
    {'model_1', 'model_2', 'model_3', 'model_4'}' ...
));
assert(isequal(fieldnames(vars), ...
    {'model_1', 'model_2', 'model_3', 'model_4'}' ...
));

% Test predictions with single point
x = 200;
[y_mean, y_sigma, y_int] = ens_model_predict(models, x, vars, params);

assert(round(y_mean, 4) == 138.5310);
assert(isequaln(y_sigma, nan));
assert(isequal(round(y_int, 4), [3.0000  141.8462]));

return
% TODO: Finish testing


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
    % Note: builtin() is needed here because other code in the
    %   MATLAB workspace overrides the built-in feval function.
    [model, vars] = builtin("feval", ...
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
    % Note: builtin() is needed here because other code in the
    %   MATLAB workspace overrides the built-in feval function.
    [model, vars] = builtin("feval", ...
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

