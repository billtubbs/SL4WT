% Test fp2 model setup, prediction and update functions
%

clear variables

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";


%% Test initialization and prediction with no data

Load = double.empty(0, 1);
Power = double.empty(0, 1);
data = table(Load, Power);

params = struct();
params.predictorNames = "Load";
params.responseNames = "Power";
params.inputTransform.x = "@(x) x";
params.inputTransform.x_inv = "@(x, y) x";
params.outputTransform.y = "@(x, y) y.*x";
params.outputTransform.y_inv = "@(x, y) y./x";
params.prior.y = "@(x) 0.7.*ones(size(x))";
params.prior.y_sigma = "@(x) 0.1.*ones(size(x))";
params.prior.y_int1 = "@(x) 0.54.*ones(size(x))";
params.prior.y_int2 = "@(x) 0.86.*ones(size(x))";
params.significance = 0.1;

% Initialize model
[model, vars] = fp2_model_setup(data, params);

assert(isa(vars.inputTransform.x, 'function_handle'))
assert(isa(vars.inputTransform.x_inv, 'function_handle'))
assert(isa(vars.outputTransform.y, 'function_handle'))
assert(isa(vars.outputTransform.y_inv, 'function_handle'))
assert(isa(vars.prior.y, 'function_handle'))
assert(isa(vars.prior.y_sigma, 'function_handle'))
assert(isa(vars.prior.y_int1, 'function_handle'))
assert(isa(vars.prior.y_int2, 'function_handle'))
assert(vars.use_fitted_model == false)
assert(vars.significance == params.significance)

% Test predictions with input vector
x = [50 100 150 200]';
[y_mean, y_sigma, y_int] = fp2_model_predict(model, x, vars, params);

assert(isequal(y_mean, [35 70 105 140]'))
assert(isequal(y_sigma, [5 10 15 20]'))
assert(isequal(y_int, [ ...
    27    43
    54    86
    81   129
   108   172
]))


%% Test initialization and prediction with 3 data points

Load = [50 100 150]';
Power = [35.05 70.18 104.77]';
data = table(Load, Power);

params = struct();
params.predictorNames = "Load";
params.responseNames = "Power";
params.inputTransform.x = "@(x) x";
params.inputTransform.x_inv = "@(x, y) x";
params.outputTransform.y = "@(x, y) y.*x";
params.outputTransform.y_inv = "@(x, y) y./x";
params.prior.y = "@(x, y) 0.7";
params.prior.y_sigma = "@(x, y) 0.1";
params.prior.y_int1 = "@(x, y) 0.54";
params.prior.y_int2 = "@(x, y) 0.86";
params.significance = 0.1;

% Initialize model
[model, vars] = fp2_model_setup(data, params);

assert(isa(vars.inputTransform.x, 'function_handle'))
assert(isa(vars.inputTransform.x_inv, 'function_handle'))
assert(isa(vars.outputTransform.y, 'function_handle'))
assert(isa(vars.outputTransform.y_inv, 'function_handle'))
assert(isa(vars.prior.y, 'function_handle'))
assert(isa(vars.prior.y_sigma, 'function_handle'))
assert(isa(vars.prior.y_int1, 'function_handle'))
assert(isa(vars.prior.y_int2, 'function_handle'))
assert(vars.use_fitted_model == false)
assert(vars.significance == params.significance)

% Test predictions with input vector
x = [50 100 150 200]';
[y_mean, y_sigma, y_int] = fp2_model_predict(model, x, vars, params);

specific_energy = data.Power ./ data.Load;
assert(isequal(y_mean, mean(specific_energy) .* x));
assert(isequal(y_sigma, std(specific_energy) .* x));

% Calculate confidence interval
intervals = [0.5.*vars.significance 1-0.5.*vars.significance];
n = length(specific_energy);
se = std(specific_energy) ./ sqrt(n);  % Standard Error
ts = tinv(intervals, n - 1);  % T-Score
y_int_calc = (mean(specific_energy) + ts .* se) .* x;
assert(isequal(y_int_calc, y_int));



%% Test with config file

% Load configuration file
filepath = fullfile(test_dir, test_data_dir, "test_config_fp2.yaml");
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
F_test_chk = [
    219.72
    10360.44
    4.58
    5.02
    5.94
];
specific_energy_chk = [
    0.827458
    0.749027
    0.753088
    0.755756
    0.731189
];
se_sigma_chk = [
    0.055846
    0.040256
    0.135383
    0.135017
    0.144064
];
se_int_chk = [
    0.733310 0.921607
    0.681161 0.816893
    0.524853 0.981323
    0.528137 0.983374
    0.488318 0.974060
];

machine_names = string(fieldnames(config.machines))';
for i = 1:numel(machine_names)
    machine = machine_names(i);
    model_name = config.machines.(machine).model;
    model_config = config.models.(model_name);

    % Run model setup script
    [model, vars] = feval( ...
        model_config.setupFcn, ...
        training_data.(machine), ...
        model_config.params ...
    );
    %fprintf("%.6f %.6f\n", model.anova.F')

    % Check model fit was good in all cases
    assert(vars.use_fitted_model)
    assert(round(model.anova.F(1), 2), F_test_chk(i));
    assert(vars.significance == model_config.params.significance)

    % Save for use below
    models.(machine) = model;
    model_vars.(machine) = vars;

end

% Make predictions with one model
machine = "machine_1";
op_limits = config.machines.(machine).params.op_limits;
model = config.machines.(machine).model;
model_config = config.models.(model);
x = linspace(op_limits(1), op_limits(2), 101)';
[y_mean, y_sigma, y_int] = fp2_model_predict( ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config ...
);

% % Plot predictions and data
% figure(1); clf
% make_statdplot(y_mean, y_int(:, 1), y_int(:, 2), x, ...
%     training_data.(machine){:, "Power"}, ...
%     training_data.(machine){:, "Load"}, ...
%     "Load", "Power")
% p = get(gcf, 'Position');
% set(gcf, 'Position', [p(1:2) 320 210])

% Check outputs
% Use this command to find these values:
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_mean)
assert(isequal( ...
    round(y_mean, 4), [
   48.8538    49.8620    50.8461    51.8062    52.7423    53.6543 ...
   54.5422    55.4061    56.2460    57.0618    57.8536    58.6213 ...
   59.3650    60.0846    60.7802    61.4518    62.0993    62.7227 ...
   63.3221    63.8975    64.4488    64.9761    65.4794    65.9585 ...
   66.4137    66.8448    67.2519    67.6349    67.9938    68.3288 ...
   68.6396    68.9265    69.1893    69.4280    69.6427    69.8334 ...
   70.0000    70.1425    70.2611    70.3555    70.4260    70.4723 ...
   70.4947    70.4930    70.4672    70.4174    70.3436    70.2457 ...
   70.1238    69.9778    69.8078    69.6137    69.3956    69.1535 ...
   68.8873    68.5970    68.2828    67.9444    67.5821    67.1956 ...
   66.7852    66.3507    65.8921    65.4095    64.9029    64.3722 ...
   63.8174    63.2387    62.6358    62.0090    61.3581    60.6831 ...
   59.9841    59.2611    58.5140    57.7428    56.9477    56.1284 ...
   55.2852    54.4178    53.5265    52.6111    51.6716    50.7081 ...
   49.7206    48.7090    47.6734    46.6137    45.5300    44.4222 ...
   43.2904    42.1346    40.9547    39.7507    38.5228    37.2707 ...
   35.9946    34.6945    33.3704    32.0221    30.6499 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_sigma)
assert(isequal( ...
    round(y_sigma, 4), [ ...
    0.2977     0.3064     0.3151     0.3239     0.3326     0.3413 ...
    0.3500     0.3587     0.3674     0.3762     0.3849     0.3936 ...
    0.4023     0.4110     0.4198     0.4285     0.4372     0.4459 ...
    0.4546     0.4634     0.4721     0.4808     0.4895     0.4982 ...
    0.5069     0.5157     0.5244     0.5331     0.5418     0.5505 ...
    0.5593     0.5680     0.5767     0.5854     0.5941     0.6028 ...
    0.6116     0.6203     0.6290     0.6377     0.6464     0.6552 ...
    0.6639     0.6726     0.6813     0.6900     0.6987     0.7075 ...
    0.7162     0.7249     0.7336     0.7423     0.7511     0.7598 ...
    0.7685     0.7772     0.7859     0.7946     0.8034     0.8121 ...
    0.8208     0.8295     0.8382     0.8470     0.8557     0.8644 ...
    0.8731     0.8818     0.8906     0.8993     0.9080     0.9167 ...
    0.9254     0.9341     0.9429     0.9516     0.9603     0.9690 ...
    0.9777     0.9865     0.9952     1.0039     1.0126     1.0213 ...
    1.0300     1.0388     1.0475     1.0562     1.0649     1.0736 ...
    1.0824     1.0911     1.0998     1.1085     1.1172     1.1259 ...
    1.1347     1.1434     1.1521     1.1608     1.1695 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 1))
assert(isequal( ...
    round(y_int(:, 1), 4), [ ...
   47.3286    48.4129    49.4663    50.4841    51.4606    52.3897 ...
   53.2661    54.0856    54.8470    55.5510    56.2000    56.7974 ...
   57.3462    57.8493    58.3090    58.7271    59.1051    59.4442 ...
   59.7451    60.0087    60.2353    60.4256    60.5797    60.6980 ...
   60.7807    60.8280    60.8400    60.8169    60.7587    60.6657 ...
   60.5377    60.3749    60.1774    59.9452    59.6784    59.3769 ...
   59.0409    58.6702    58.2651    57.8254    57.3512    56.8426 ...
   56.2995    55.7219    55.1099    54.4635    53.7827    53.0675 ...
   52.3178    51.5338    50.7154    49.8626    48.9755    48.0540 ...
   47.0981    46.1079    45.0833    44.0243    42.9311    41.8035 ...
   40.6415    39.4452    38.2146    36.9496    35.6503    34.3167 ...
   32.9488    31.5465    30.1100    28.6391    27.1338    25.5943 ...
   24.0205    22.4123    20.7698    19.0930    17.3819    15.6365 ...
   13.8568    12.0428    10.1945     8.3118     6.3949     4.4437 ...
    2.4581     0.4383    -1.6159    -3.7043    -5.8271    -7.9842 ...
  -10.1755   -12.4012   -14.6611   -16.9554   -19.2839   -21.6468 ...
  -24.0439   -26.4754   -28.9411   -31.4412   -33.9755 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 2))
assert(isequal( ...
    round(y_int(:, 2), 4), [ ...
   50.3790    51.3111    52.2259    53.1283    54.0239    54.9188 ...
   55.8184    56.7266    57.6450    58.5726    59.5071    60.4452 ...
   61.3838    62.3200    63.2515    64.1764    65.0934    66.0013 ...
   66.8992    67.7864    68.6623    69.5267    70.3790    71.2191 ...
   72.0467    72.8616    73.6637    74.4528    75.2289    75.9919 ...
   76.7416    77.4780    78.2011    78.9108    79.6070    80.2898 ...
   80.9591    81.6148    82.2570    82.8857    83.5007    84.1021 ...
   84.6899    85.2640    85.8245    86.3714    86.9045    87.4240 ...
   87.9297    88.4218    88.9002    89.3648    89.8158    90.2530 ...
   90.6765    91.0862    91.4822    91.8645    92.2330    92.5878 ...
   92.9289    93.2561    93.5696    93.8694    94.1554    94.4276 ...
   94.6861    94.9308    95.1617    95.3789    95.5823    95.7719 ...
   95.9478    96.1098    96.2581    96.3926    96.5134    96.6203 ...
   96.7135    96.7929    96.8585    96.9103    96.9484    96.9726 ...
   96.9831    96.9798    96.9627    96.9318    96.8871    96.8286 ...
   96.7564    96.6703    96.5705    96.4568    96.3294    96.1882 ...
   96.0332    95.8644    95.6818    95.4855    95.2753 ...
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
[models.(machine), vars] = fp2_model_update(models.(machine), ...
    training_data.(machine), vars, model_config.params);

% Check vars updated
assert(vars.use_fitted_model)
assert(round(models.(machine).anova.F(1), 2), 85.75);

% Re-do predictions with model
[y_mean, y_sigma, y_int] = fp2_model_predict( ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config ...
);

% % Plot predictions and data
% figure(2); clf
% make_statdplot(y_mean, y_int(:, 1), y_int(:, 2), x, ...
%     training_data.(machine){:, "Power"}, ...
%     training_data.(machine){:, "Load"}, ...
%     "Load", "Power")
% p = get(gcf, 'Position');
% set(gcf, 'Position', [p(1:2) 320 210])

% Check outputs
% Use this command to find these values:
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_mean)
assert(isequal( ...
    round(y_mean, 4), ...
    [  ...
   48.5762    49.6487    50.7012    51.7338    52.7464    53.7391 ...
   54.7119    55.6648    56.5978    57.5108    58.4039    59.2771 ...
   60.1303    60.9636    61.7770    62.5705    63.3440    64.0977 ...
   64.8313    65.5451    66.2390    66.9129    67.5669    68.2009 ...
   68.8151    69.4093    69.9836    70.5379    71.0724    71.5869 ...
   72.0815    72.5561    73.0108    73.4456    73.8605    74.2555 ...
   74.6305    74.9856    75.3208    75.6360    75.9314    76.2068 ...
   76.4622    76.6978    76.9134    77.1091    77.2849    77.4407 ...
   77.5766    77.6926    77.7887    77.8649    77.9211    77.9574 ...
   77.9737    77.9702    77.9467    77.9033    77.8399    77.7567 ...
   77.6535    77.5304    77.3873    77.2243    77.0415    76.8386 ...
   76.6159    76.3732    76.1106    75.8281    75.5257    75.2033 ...
   74.8610    74.4988    74.1166    73.7145    73.2925    72.8506 ...
   72.3887    71.9070    71.4053    70.8836    70.3421    69.7806 ...
   69.1992    68.5979    67.9766    67.3354    66.6743    65.9933 ...
   65.2923    64.5714    63.8306    63.0699    62.2892    61.4886 ...
   60.6681    59.8276    58.9673    58.0870    57.1868 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_sigma)
assert(isequal( ...
    round(y_sigma, 4), ...
    [   ...
    0.6865     0.7066     0.7267     0.7468     0.7669     0.7870 ...
    0.8071     0.8273     0.8474     0.8675     0.8876     0.9077 ...
    0.9278     0.9479     0.9680     0.9881     1.0082     1.0283 ...
    1.0484     1.0685     1.0886     1.1087     1.1288     1.1489 ...
    1.1690     1.1891     1.2093     1.2294     1.2495     1.2696 ...
    1.2897     1.3098     1.3299     1.3500     1.3701     1.3902 ...
    1.4103     1.4304     1.4505     1.4706     1.4907     1.5108 ...
    1.5309     1.5510     1.5711     1.5912     1.6114     1.6315 ...
    1.6516     1.6717     1.6918     1.7119     1.7320     1.7521 ...
    1.7722     1.7923     1.8124     1.8325     1.8526     1.8727 ...
    1.8928     1.9129     1.9330     1.9531     1.9732     1.9934 ...
    2.0135     2.0336     2.0537     2.0738     2.0939     2.1140 ...
    2.1341     2.1542     2.1743     2.1944     2.2145     2.2346 ...
    2.2547     2.2748     2.2949     2.3150     2.3351     2.3552 ...
    2.3753     2.3955     2.4156     2.4357     2.4558     2.4759 ...
    2.4960     2.5161     2.5362     2.5563     2.5764     2.5965 ...
    2.6166     2.6367     2.6568     2.6769     2.6970 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 1))
assert(isequal( ...
    round(y_int(:, 1), 4), ...
    [   ...
   47.0651    48.1741    49.2636    50.3325    51.3795    52.4031 ...
   53.4017    54.3732    55.3157    56.2272    57.1059    57.9503 ...
   58.7594    59.5326    60.2701    60.9721    61.6393    62.2726 ...
   62.8729    63.4409    63.9775    64.4833    64.9591    65.4052 ...
   65.8223    66.2107    66.5707    66.9025    67.2065    67.4829 ...
   67.7317    67.9532    68.1475    68.3147    68.4549    68.5681 ...
   68.6545    68.7142    68.7470    68.7532    68.7328    68.6858 ...
   68.6121    68.5120    68.3853    68.2321    68.0525    67.8464 ...
   67.6139    67.3550    67.0697    66.7580    66.4199    66.0555 ...
   65.6647    65.2476    64.8041    64.3343    63.8382    63.3157 ...
   62.7670    62.1920    61.5906    60.9630    60.3091    59.6289 ...
   58.9224    58.1896    57.4306    56.6453    55.8337    54.9959 ...
   54.1318    53.2415    52.3248    51.3820    50.4129    49.4175 ...
   48.3959    47.3480    46.2739    45.1736    44.0470    42.8942 ...
   41.7151    40.5098    39.2783    38.0205    36.7365    35.4262 ...
   34.0897    32.7270    31.3381    29.9229    28.4815    27.0138 ...
   25.5200    23.9999    22.4536    20.8810    19.2823 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 2))
assert(isequal( ...
    round(y_int(:, 2), 4), ...
    [   ...
   50.0873    51.1232    52.1387    53.1350    54.1133    55.0751 ...
   56.0222    56.9565    57.8799    58.7944    59.7019    60.6038 ...
   61.5012    62.3946    63.2840    64.1689    65.0487    65.9227 ...
   66.7898    67.6494    68.5005    69.3424    70.1747    70.9966 ...
   71.8078    72.6079    73.3965    74.1733    74.9382    75.6909 ...
   76.4312    77.1590    77.8742    78.5766    79.2662    79.9428 ...
   80.6065    81.2571    81.8945    82.5188    83.1299    83.7278 ...
   84.3124    84.8836    85.4415    85.9861    86.5172    87.0350 ...
   87.5394    88.0303    88.5077    88.9717    89.4222    89.8592 ...
   90.2828    90.6928    91.0893    91.4722    91.8417    92.1976 ...
   92.5399    92.8688    93.1840    93.4857    93.7738    94.0484 ...
   94.3094    94.5568    94.7907    95.0109    95.2176    95.4107 ...
   95.5902    95.7561    95.9084    96.0471    96.1722    96.2837 ...
   96.3816    96.4659    96.5366    96.5937    96.6371    96.6670 ...
   96.6833    96.6859    96.6749    96.6503    96.6121    96.5603 ...
   96.4949    96.4158    96.3231    96.2168    96.0969    95.9633 ...
   95.8162    95.6554    95.4810    95.2929    95.0912 ...
]'))
