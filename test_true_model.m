% Test fixed polynomial model setup, prediction and update 
% functions. This model is used to represent the true machines.
%

clear variables

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";


%% Test initialization

data = [];

params = struct();
params.predictorNames = "Load";
params.responseNames = "Power";
params.coeff = [-9e-8, 4e-5, -0.0052, 0.7765, 15.661];

% Initialize the model
[model, vars] = fixed_poly_model_setup(data, params);

assert(isequaln(model, struct))
assert(isequaln(vars, struct))

% Test predictions with single point
x = 200;
[y_mean, y_sigma, y_int] = fixed_poly_model_predict(model, x, vars, params);

assert(round(y_mean, 4) == 138.9610);
assert(y_sigma == 0);
assert(isequal(round(y_int, 4), [138.9610 138.9610]));

% define and test a function handle
f_handle = @(model, x, vars, params) fixed_poly_model_predict(model, x, vars, params);
[y_mean, y_sigma, y_int] = f_handle(model, x, vars, params);

assert(round(y_mean, 4) == 138.9610);
assert(y_sigma == 0);
assert(isequal(round(y_int, 4), [138.9610 138.9610]));

% Test again using feval with function name
f_name = "fixed_poly_model_predict";
[y_mean, y_sigma, y_int] = builtin('feval', f_name, model, x, vars, params);

assert(round(y_mean, 4) == 138.9610);
assert(y_sigma == 0);
assert(isequal(round(y_int, 4), [138.9610 138.9610]));

% Test predictions with input vector
x = [50 100 150 200]';
[y_mean, y_sigma, y_int] = fixed_poly_model_predict(model, x, vars, params);

assert(isequal(round(y_mean, 4), [45.9235 72.3110 104.5735 138.9610]'))
assert(isequal(y_sigma, zeros(4, 1)))
assert(isequal(round(y_int, 4), repmat([45.9235 72.3110 104.5735 138.9610]', 1, 2)))


%% Test with config file

% Load optimizer configuration file
filepath = fullfile(test_dir, test_data_dir, "test_config_true.yaml");
opt_config = yaml.loadFile(filepath, "ConvertToArray", true);

% (No training data for this model)
training_data = struct();

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct
models = struct();
model_vars = struct();

% Test results to compare to
coeffs_chk = [
    20.4981 0.5101
    93.6391 0.3797
    64.7529 0.5433
    64.9354 0.5433
    67.3376 0.5391
];

machine_names = string(fieldnames(opt_config.machines))';
for i = 1:numel(machine_names)
    machine = machine_names(i);
    model_name = opt_config.machines.(machine).model;
    model_config = opt_config.models.(model_name);

    % Run model setup script
    [model, vars] = feval( ...
        model_config.setupFcn, ...
        training_data, ...
        model_config.params ...
    );

    % No models or variables
    assert(isequaln(model, struct))
    assert(isequaln(vars, struct))

end

% Make predictions with one model
machine = "machine_1";
op_limits = opt_config.machines.(machine).params.op_limits;
model_name = opt_config.machines.(machine).model;
model_config = opt_config.models.(model_name);
x = linspace(op_limits(1), op_limits(2), 101)';
[y_mean, y_sigma, y_int] = fixed_poly_model_predict( ...
    [], ...  % no model
    x, ...
    [], ...  % no model_vars
    model_config.params ...
);

% % Plot predictions and data
% figure(1); clf
% make_statplot(y_mean, y_int(:, 1), y_int(:, 2), x, ...
%     "Load", "Power")
% p = get(gcf, 'Position');
% set(gcf, 'Position', [p(1:2) 320 210])

% Check outputs
% Use this command to find these values:
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_mean)
assert(isequal( ...
    round(y_mean, 4), [
   48.9773    49.8088    50.6398    51.4709    52.3025    53.1352 ...
   53.9694    54.8056    55.6441    56.4853    57.3297    58.1777 ...
   59.0295    59.8856    60.7463    61.6119    62.4826    63.3588 ...
   64.2407    65.1286    66.0228    66.9234    67.8306    68.7447 ...
   69.6657    70.5940    71.5295    72.4725    73.4231    74.3812 ...
   75.3472    76.3208    77.3024    78.2918    79.2890    80.2942 ...
   81.3072    82.3281    83.3568    84.3932    85.4373    86.4890 ...
   87.5481    88.6145    89.6881    90.7688    91.8564    92.9506 ...
   94.0514    95.1584    96.2714    97.3903    98.5146    99.6442 ...
  100.7788   101.9179   103.0614   104.2089   105.3600   106.5143 ...
  107.6715   108.8311   109.9927   111.1559   112.3203   113.4853 ...
  114.6505   115.8154   116.9795   118.1423   119.3031   120.4615 ...
  121.6168   122.7685   123.9159   125.0585   126.1957   127.3266 ...
  128.4507   129.5673   130.6757   131.7752   132.8650   133.9444 ...
  135.0127   136.0689   137.1125   138.1424   139.1580   140.1583 ...
  141.1426   142.1099   143.0594   143.9901   144.9011   145.7915 ...
  146.6604   147.5067   148.3295   149.1278   149.9006
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_sigma)
assert(all(isequal(y_sigma, zeros(size(x)))));

% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 1))
assert(all(isequal(y_int, [y_mean y_mean])));
