% Test model setup, prediction and update functions for
% the ensemble model.
%

clear all

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";


%% Test initialization with data

Load = [50 100 150]';
Power = [35.05 70.18 104.77]';
data = table(Load, Power);

model_1 = struct;
model_1.setupFcn = "lin_model_setup";
model_1.predictFcn = "lin_model_predict";
model_1.updateFcn = "lin_model_update";
model_1.params.predictorNames = "Load";
model_1.params.responseNames = "Power";
model_1.params.significance = 0.1;

model_2 = struct;
model_2.setupFcn = "fit_model_setup";
model_2.predictFcn = "fit_model_predict";
model_2.updateFcn = "fit_model_update";
model_2.params.predictorNames = "Load";
model_2.params.responseNames = "Power";
model_2.params.significance = 0.1;
model_2.params.fit.fitType = 'poly2';

model_3 = struct;
model_3.setupFcn = "fp1_model_setup";
model_3.predictFcn = "fp1_model_predict";
model_3.updateFcn = "fp1_model_update";
model_3.params.predictorNames = "Load";
model_3.params.responseNames = "Power";
model_3.params.prior.se_sigma = 1;
model_3.params.prior.specific_energy = 0.7;
model_3.params.prior.se_int = [0.5 0.9];
model_3.params.significance = 0.1;

model_4 = struct;
model_4.setupFcn = "gpr_model_setup";
model_4.predictFcn = "gpr_model_predict";
model_4.updateFcn = "gpr_model_update";
model_4.params.predictorNames = "Load";
model_4.params.responseNames = "Power";
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


%% Test with config file

% Load configuration file
filepath = fullfile(test_dir, test_data_dir, "test_config_ens.yaml");
config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load training data from file
training_data = struct();
for machine = string(fieldnames(config.machines))'
    filename = config.machines.(machine).trainingData;
    training_data.(machine) = readtable(...
        fullfile(test_dir, test_data_dir, filename) ...
    );
end

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct
models = struct();
model_vars = struct();

% Test results to compare to
coeffs_chk = struct;
coeffs_chk.machine_1 = struct( ...
    'model_11', [0.595149 14.9863], ...
    'model_12', [0.00115465 0.352075 25.7804], ...
    'model_13', [2.12595e-05 -0.0049403 0.885024 11.2257] ...
);
coeffs_chk.machine_2 = struct( ...
    'model_21', [0.515405 58.1292], ...
    'model_22', [0.000631498 0.0580001 134.338], ...
    'model_23', [-1.02462e-06 0.00173128 -0.319653 175.865] ...
);
coeffs_chk.machine_3 = struct( ...
    'model_31', [0.553714 62.936], ...
    'model_32', [-2.25383e-05 0.575798 58.8723], ...
    'model_33', [-7.68249e-07 0.00113025 0.0540596 126.292] ...
);
coeffs_chk.machine_4 = struct( ...
    'model_31', [0.547135 64.1203], ...
    'model_32', [8.81957e-05 0.457457 80.4354], ...
    'model_33', [-8.43996e-07 0.00122079 0.0266085 128.754] ...
);
coeffs_chk.machine_5 = struct( ...
    'model_31', [0.553347 61.9386], ...
    'model_32', [4.195e-05 0.511507 70.1416], ...
    'model_33', [-7.76119e-07 0.00118508 0.00664429 134.322] ...
);

machine_names = string(fieldnames(config.machines))';
for i = 1:numel(machine_names)
    machine = machine_names(i);
    model_name = config.machines.(machine).model;
    model_config = config.models.(model_name);

    % Run model setup script
    [model, vars] = builtin("feval", ...
        model_config.setupFcn, ...
        training_data.(machine), ...
        model_config.params ...
    );

    % Check sub-model variables and params
    for sub_model_name = string(fieldnames(model_config.params.models))'
        assert(isfield(vars, sub_model_name))
        sub_model_config = model_config.params.models.(sub_model_name);
        assert(vars.(sub_model_name).significance == ...
            sub_model_config.params.significance)
        sub_model = model.(sub_model_name);
        %fprintf("%s, %s: %s\n", machine, sub_model_name, strjoin(string(round(coeffvalues(sub_model), 6, 'significant')'), " "))
        assert(isequal(round(coeffvalues(sub_model), 6, 'significant'), ...
            coeffs_chk.(machine).(sub_model_name)));
    end

    % Save for use below
    models.(machine) = model;
    model_vars.(machine) = vars;

end

% Make predictions with one model
machine = "machine_1";
op_limits = config.machines.(machine).op_limits;
model_name = config.machines.(machine).model;
model_config = config.models.(model_name);
x = linspace(op_limits(1), op_limits(2), 101)';
[y_mean, y_sigma, y_int] = builtin("feval", ...
    model_config.predictFcn, ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config.params ...
);

% % Plot predictions and data
% figure(1); clf
% make_statdplot(y_mean, y_int(:, 1), y_int(:, 2), x, training_data.Power, ...
%     training_data.Load, "Load", "Power")
% p = get(gcf, 'Position');
% set(gcf, 'Position', [p(1:2) 320 210])

% Check outputs
% Use this command to find these values:
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_mean)
assert(isequal( ...
    round(y_mean, 4), [
   48.8200    49.6991    50.5779    51.4567    52.3357    53.2151 ...
   54.0950    54.9757    55.8572    56.7399    57.6240    58.5095 ...
   59.3966    60.2857    61.1768    62.0701    62.9659    63.8643 ...
   64.7655    65.6697    66.5770    67.4878    68.4021    69.3201 ...
   70.2421    71.1681    72.0985    73.0334    73.9729    74.9174 ...
   75.8668    76.8216    77.7817    78.7475    79.7191    80.6966 ...
   81.6804    82.6705    83.6672    84.6706    85.6809    86.6984 ...
   87.7232    88.7554    89.7954    90.8432    91.8990    92.9631 ...
   94.0357    95.1168    96.2068    97.3058    98.4139    99.5314 ...
  100.6585   101.7953   102.9420   104.0989   105.2661   106.4437 ...
  107.6321   108.8313   110.0415   111.2631   112.4960   113.7406 ...
  114.9969   116.2653   117.5458   118.8388   120.1442   121.4625 ...
  122.7936   124.1379   125.4955   126.8665   128.2513   129.6499 ...
  131.0626   132.4895   133.9309   135.3869   136.8576   138.3434 ...
  139.8444   141.3607   142.8926   144.4403   146.0038   147.5835 ...
  149.1795   150.7920   152.4212   154.0673   155.7304   157.4107 ...
  159.1085   160.8239   162.5571   164.3083   166.0777 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_sigma)
assert(isequaln(y_sigma, nan(size(x))));  % TODO: Should we produce a y_sigma?

% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 1))
assert(isequal( ...
    round(y_int(:, 1), 4), [
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000 ...
]'))

% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 2))
assert(isequal( ...
    round(y_int(:, 2), 4), [
   50.3857    51.3178    52.2515    53.1867    54.1236    55.0623 ...
   56.0029    56.9455    57.8902    58.8372    59.7866    60.7384 ...
   61.6928    62.6499    63.6098    64.5725    65.5382    66.5069 ...
   67.4785    68.4533    69.4311    70.4119    71.3958    72.3827 ...
   73.3725    74.3651    75.3605    76.3586    77.3592    78.3623 ...
   79.3677    80.3754    81.3851    82.3969    83.4106    84.4260 ...
   85.4431    86.4618    87.4820    88.5036    89.5264    90.5505 ...
   91.5757    92.6019    93.6292    94.6574    95.6864    96.7163 ...
   97.7470    98.7784    99.8104   100.8431   101.8764   102.9102 ...
  103.9446   104.9795   106.0148   107.0506   108.0868   109.1234 ...
  110.1603   111.1976   112.2353   113.2732   114.3115   115.3500 ...
  116.3888   117.4279   118.4672   119.5067   120.5465   121.5864 ...
  122.6266   123.6669   124.7074   125.7481   126.7890   127.8300 ...
  128.8711   129.9124   130.9539   131.9954   133.0371   134.0790 ...
  135.1209   136.1629   137.2051   138.2473   139.2897   140.3321 ...
  141.3747   142.4173   143.4600   144.5028   145.5457   146.5886 ...
  147.6316   148.6747   149.7179   150.7611   151.8044 ...
]'))

% More data points
io_data = array2table([
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
], 'VariableNames', {'Load', 'Power'});

% Add one point to training data
training_data.machine_1 = [
    training_data.(machine);
    io_data(9, :)
];

% Test update function (trivial for GPs)
[models.(machine), model_vars.(machine)] = ens_model_update( ...
    models.(machine), ...
    training_data.(machine), ...
    model_vars.(machine), ...
    model_config.params ...
);

% Check vars updated
for sub_model_name = string(fieldnames(model_config.params.models))'
    sub_model_config = model_config.params.models.(sub_model_name);
    assert(model_vars.(machine).(sub_model_name).significance == ...
        sub_model_config.params.significance)
    sub_model = models.(machine).(sub_model_name);
    % Check the coefficients are not the same now
    assert(~isequal(round(coeffvalues(sub_model), 6, 'significant'), ...
        coeffs_chk.(machine).(sub_model_name)));
end

% Re-do predictions with new model
[y_mean, y_sigma, y_int] = ens_model_predict( ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config.params ...
);

% % Plot predictions and data
% figure(2); clf
% make_statdplot(y_mean, y_int(:, 1), y_int(:, 2), x, training_data.Power', ...
%     training_data.Load', "Load", "Power")
% p = get(gcf, 'Position');
% set(gcf, 'Position', [p(1:2) 320 210])

% Check outputs changed
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_mean)
assert(isequal( ...
    round(y_mean, 4), [
   48.7333    49.5927    50.4547    51.3195    52.1871    53.0575 ...
   53.9309    54.8072    55.6866    56.5692    57.4549    58.3439 ...
   59.2363    60.1320    61.0312    61.9339    62.8402    63.7502 ...
   64.6640    65.5815    66.5029    67.4282    68.3576    69.2910 ...
   70.2285    71.1702    72.1163    73.0666    74.0214    74.9806 ...
   75.9444    76.9127    77.8858    78.8636    79.8462    80.8336 ...
   81.8260    82.8235    83.8260    84.8336    85.8465    86.8646 ...
   87.8881    88.9169    89.9513    90.9912    92.0367    93.0879 ...
   94.1449    95.2077    96.2763    97.3509    98.4315    99.5182 ...
  100.6111   101.7101   102.8155   103.9272   105.0453   106.1699 ...
  107.3010   108.4388   109.5833   110.7345   111.8926   113.0575 ...
  114.2294   115.4083   116.5943   117.7875   118.9878   120.1955 ...
  121.4105   122.6330   123.8630   125.1005   126.3456   127.5985 ...
  128.8591   130.1275   131.4038   132.6881   133.9804   135.2808 ...
  136.5894   137.9062   139.2313   140.5648   141.9067   143.2571 ...
  144.6161   145.9837   147.3600   148.7451   150.1390   151.5418 ...
  152.9536   154.3744   155.8044   157.2435   158.6918
]'))

assert(isequaln(y_sigma, nan(size(x))));  % TODO: Should we produce a y_sigma?

% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 1))
assert(isequal( ...
    round(y_int(:, 1), 4), ...
    [   ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000     3.0000 ...
    3.0000     3.0000     3.0000     3.0000     3.0000
]'))

% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 2))
assert(isequal( ...
    round(y_int(:, 2), 4), ...
    [   ...
   50.0101    50.9334    51.8581    52.7843    53.7121    54.6416 ...
   55.5729    56.5062    57.4416    58.3793    59.3193    60.2619 ...
   61.2072    62.1553    63.1063    64.0604    65.0177    65.9783 ...
   66.9423    67.9097    68.8805    69.8548    70.8326    71.8138 ...
   72.7984    73.7862    74.7772    75.7712    76.7682    77.7679 ...
   78.7704    79.7753    80.7825    81.7920    82.8036    83.8171 ...
   84.8324    85.8495    86.8680    87.8881    88.9095    89.9322 ...
   90.9560    91.9809    93.0069    94.0338    95.0615    96.0901 ...
   97.1195    98.1495    99.1803   100.2116   101.2435   102.2760 ...
  103.3090   104.3424   105.3763   106.4106   107.4453   108.4804 ...
  109.5158   110.5515   111.5876   112.6239   113.6605   114.6974 ...
  115.7345   116.7719   117.8094   118.8472   119.8852   120.9234 ...
  121.9617   123.0002   124.0389   125.0778   126.1167   127.1559 ...
  128.1951   129.2345   130.2740   131.3136   132.3534   133.3932 ...
  134.4332   135.4732   136.5133   137.5536   138.5939   139.6343 ...
  140.6747   141.7153   142.7559   143.7966   144.8374   145.8782 ...
  146.9191   147.9601   149.0011   150.0422   151.0833 ...
]'))


