% Test fp1 model setup, prediction and update functions
%

clear variables

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";


%% Test initialization and prediction without data 

Load = double.empty(0, 1);
Power = double.empty(0, 1);
data = table(Load, Power);

params = struct();
params.predictorNames = "Load";
params.responseNames = "Power";
params.prior.se_sigma = 1;
params.prior.specific_energy = 0.7;
params.prior.se_int = [0.5 0.9];
params.significance = 0.1;

% Initialize model
[model, vars] = fp1_model_setup(data, params);

assert(vars.significance == params.significance)
assert(vars.specific_energy == params.prior.specific_energy)
assert(vars.se_sigma == params.prior.se_sigma)
assert(isequal(vars.se_int, params.prior.se_int))

% Test predictions with input vector
x = [50 100 150 200]';
[y_mean, y_sigma, y_int] = fp1_model_predict(model, x, vars, params);

assert(isequal(y_mean, [35 70 105 140]'))
assert(isequal(y_sigma, [50 100 150 200]'))
assert(isequal(y_int, [ ...
    25    45
    50    90
    75   135
   100   180
]))


%% Test initialization and prediction with data

Load = [50 100 150]';
Power = [35.05 70.18 104.77]';
data = table(Load, Power);

params = struct();
params.predictorNames = "Load";
params.responseNames = "Power";
params.prior.se_sigma = 1;
params.prior.specific_energy = 0.7;
params.prior.se_int = [0.5 0.9];
params.significance = 0.1;

% Initialize model
[model, vars] = fp1_model_setup(data, params);

specific_energy = data.Power ./ data.Load;
assert(isequal(fieldnames(vars), {'significance', ...
    'specific_energy', 'se_sigma', 'se_int'}'))
assert(vars.specific_energy == mean(specific_energy));
assert(vars.se_sigma == std(specific_energy));

% Test predictions with single point
x = 200;
[y_mean, y_sigma, y_int] = fp1_model_predict(model, x, vars, params);

assert(y_mean == mean(specific_energy) .* x);
assert(y_sigma == std(specific_energy) .* x);

% Calculate confidence interval
intervals = [0.5.*vars.significance 1-0.5.*vars.significance];
n = length(specific_energy);
se = std(specific_energy) ./ sqrt(n);  % Standard Error
ts = tinv(intervals, n - 1);  % T-Score
y_int_calc = (vars.specific_energy + ts .* se) .* x;
assert(isequal(y_int_calc, y_int));


%% Test with config file

% Load configuration file
filepath = fullfile(test_dir, test_data_dir, "test_config_fp1.yaml");
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
    %fprintf("%.6f %.6f\n", vars.se_int')

    % Check selected model variables and params
    assert(isequal(model, []));
    assert(vars.significance == model_config.params.significance)
    assert(round(vars.specific_energy, 6) == specific_energy_chk(i))
    assert(round(vars.se_sigma, 6) == se_sigma_chk(i))
    assert(isequal(round(vars.se_int, 6), se_int_chk(i, :)))

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
[y_mean, y_sigma, y_int] = fp1_model_predict( ...
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
   46.3377    47.6947    49.0517    50.4088    51.7658    53.1228 ...
   54.4799    55.8369    57.1939    58.5510    59.9080    61.2650 ...
   62.6221    63.9791    65.3361    66.6931    68.0502    69.4072 ...
   70.7642    72.1213    73.4783    74.8353    76.1924    77.5494 ...
   78.9064    80.2635    81.6205    82.9775    84.3346    85.6916 ...
   87.0486    88.4057    89.7627    91.1197    92.4768    93.8338 ...
   95.1908    96.5478    97.9049    99.2619   100.6189   101.9760 ...
  103.3330   104.6900   106.0471   107.4041   108.7611   110.1182 ...
  111.4752   112.8322   114.1893   115.5463   116.9033   118.2604 ...
  119.6174   120.9744   122.3315   123.6885   125.0455   126.4025 ...
  127.7596   129.1166   130.4736   131.8307   133.1877   134.5447 ...
  135.9018   137.2588   138.6158   139.9729   141.3299   142.6869 ...
  144.0440   145.4010   146.7580   148.1151   149.4721   150.8291 ...
  152.1862   153.5432   154.9002   156.2572   157.6143   158.9713 ...
  160.3283   161.6854   163.0424   164.3994   165.7565   167.1135 ...
  168.4705   169.8276   171.1846   172.5416   173.8987   175.2557 ...
  176.6127   177.9698   179.3268   180.6838   182.0409 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_sigma)
assert(isequal( ...
    round(y_sigma, 4), [ ...
    3.1274     3.2190     3.3106     3.4022     3.4937     3.5853 ...
    3.6769     3.7685     3.8601     3.9517     4.0433     4.1349 ...
    4.2265     4.3180     4.4096     4.5012     4.5928     4.6844 ...
    4.7760     4.8676     4.9592     5.0507     5.1423     5.2339 ...
    5.3255     5.4171     5.5087     5.6003     5.6919     5.7834 ...
    5.8750     5.9666     6.0582     6.1498     6.2414     6.3330 ...
    6.4246     6.5162     6.6077     6.6993     6.7909     6.8825 ...
    6.9741     7.0657     7.1573     7.2489     7.3404     7.4320 ...
    7.5236     7.6152     7.7068     7.7984     7.8900     7.9816 ...
    8.0731     8.1647     8.2563     8.3479     8.4395     8.5311 ...
    8.6227     8.7143     8.8059     8.8974     8.9890     9.0806 ...
    9.1722     9.2638     9.3554     9.4470     9.5386     9.6301 ...
    9.7217     9.8133     9.9049     9.9965    10.0881    10.1797 ...
   10.2713    10.3628    10.4544    10.5460    10.6376    10.7292 ...
   10.8208    10.9124    11.0040    11.0956    11.1871    11.2787 ...
   11.3703    11.4619    11.5535    11.6451    11.7367    11.8283 ...
   11.9198    12.0114    12.1030    12.1946    12.2862 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 1))
assert(isequal( ...
    round(y_int(:, 1), 4), [ ...
   41.0653    42.2680    43.4706    44.6732    45.8758    47.0785 ...
   48.2811    49.4837    50.6864    51.8890    53.0916    54.2942 ...
   55.4969    56.6995    57.9021    59.1048    60.3074    61.5100 ...
   62.7126    63.9153    65.1179    66.3205    67.5231    68.7258 ...
   69.9284    71.1310    72.3337    73.5363    74.7389    75.9415 ...
   77.1442    78.3468    79.5494    80.7521    81.9547    83.1573 ...
   84.3599    85.5626    86.7652    87.9678    89.1704    90.3731 ...
   91.5757    92.7783    93.9810    95.1836    96.3862    97.5888 ...
   98.7915    99.9941   101.1967   102.3994   103.6020   104.8046 ...
  106.0072   107.2099   108.4125   109.6151   110.8177   112.0204 ...
  113.2230   114.4256   115.6283   116.8309   118.0335   119.2361 ...
  120.4388   121.6414   122.8440   124.0467   125.2493   126.4519 ...
  127.6545   128.8572   130.0598   131.2624   132.4650   133.6677 ...
  134.8703   136.0729   137.2756   138.4782   139.6808   140.8834 ...
  142.0861   143.2887   144.4913   145.6939   146.8966   148.0992 ...
  149.3018   150.5045   151.7071   152.9097   154.1123   155.3150 ...
  156.5176   157.7202   158.9229   160.1255   161.3281 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_int(:, 2))
assert(isequal( ...
    round(y_int(:, 2), 4), [ ...
   51.6100    53.1214    54.6329    56.1443    57.6557    59.1672 ...
   60.6786    62.1901    63.7015    65.2129    66.7244    68.2358 ...
   69.7472    71.2587    72.7701    74.2815    75.7930    77.3044 ...
   78.8159    80.3273    81.8387    83.3502    84.8616    86.3730 ...
   87.8845    89.3959    90.9073    92.4188    93.9302    95.4416 ...
   96.9531    98.4645    99.9760   101.4874   102.9988   104.5103 ...
  106.0217   107.5331   109.0446   110.5560   112.0674   113.5789 ...
  115.0903   116.6017   118.1132   119.6246   121.1361   122.6475 ...
  124.1589   125.6704   127.1818   128.6932   130.2047   131.7161 ...
  133.2275   134.7390   136.2504   137.7619   139.2733   140.7847 ...
  142.2962   143.8076   145.3190   146.8305   148.3419   149.8533 ...
  151.3648   152.8762   154.3876   155.8991   157.4105   158.9220 ...
  160.4334   161.9448   163.4563   164.9677   166.4791   167.9906 ...
  169.5020   171.0134   172.5249   174.0363   175.5477   177.0592 ...
  178.5706   180.0821   181.5935   183.1049   184.6164   186.1278 ...
  187.6392   189.1507   190.6621   192.1735   193.6850   195.1964 ...
  196.7078   198.2193   199.7307   201.2422   202.7536 ...
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
[models.(machine), vars] = fp1_model_update(models.(machine), ...
    training_data.(machine), vars, model_config.params);

% Check vars updated
assert(vars.significance == model_config.params.significance)
assert(round(vars.specific_energy, 6) ~= specific_energy_chk(1))
assert(round(vars.specific_energy, 6) == 0.803391)
assert(round(vars.se_sigma, 6) ~= se_sigma_chk(1))
assert(round(vars.se_sigma, 6), 0.075308)
assert(~isequal(round(vars.se_int, 6), se_int_chk(1, :)))
assert(isequal(round(vars.se_int, 6), [0.725372 0.881409]))

% Re-do predictions with model
[y_mean, y_sigma, y_int] = fp1_model_predict( ...
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
assert(~isequal( ...
    round(y_mean, 4), ...
    [   ...
   49.0319   49.8783   50.7335   51.5965   52.4662   53.3416 ...
   54.2217   55.1053   55.9914   56.8789   57.7667   58.6537 ...
   59.5388   60.4211   61.2992   62.1724   63.0393   63.8991 ...
   64.7506   65.5929   66.4250   67.2459   68.0546   68.8503 ...
   69.6319   70.3988   71.1499   71.8845   72.6018   73.3010 ...
   73.9816   74.6427   75.2837   75.9041   76.5032   77.0806 ...
   77.6358   78.1683   78.6778   79.1638   79.6261   80.0644 ...
   80.4785   80.8682   81.2333   81.5738   81.8895   82.1805 ...
   82.4467   82.6883   82.9054   83.0980   83.2663   83.4106 ...
   83.5312   83.6282   83.7020   83.7529   83.7813   83.7877 ...
   83.7724   83.7360   83.6788   83.6014   83.5044   83.3882 ...
   83.2535   83.1008   82.9307   82.7439   82.5409   82.3225 ...
   82.0892   81.8417   81.5807   81.3068   81.0207   80.7230 ...
   80.4146   80.0959   79.7677   79.4307   79.0855   78.7327 ...
   78.3730   78.0071   77.6356   77.2591   76.8781   76.4934 ...
   76.1055   75.7149   75.3223   74.9281   74.5328   74.1371 ...
   73.7414   73.3461   72.9517   72.5587   72.1675 ...
]'))
assert(~isequal( ...
    round(y_sigma, 4), ...
    [   ...
    0.1543    0.1384    0.1355    0.1433    0.1580    0.1761 ...
    0.1952    0.2138    0.2312    0.2468    0.2601    0.2708 ...
    0.2786    0.2832    0.2845    0.2822    0.2761    0.2661 ...
    0.2522    0.2346    0.2139    0.1915    0.1705    0.1563 ...
    0.1573    0.1799    0.2239    0.2853    0.3604    0.4474 ...
    0.5449    0.6526    0.7702    0.8975    1.0344    1.1810 ...
    1.3372    1.5031    1.6786    1.8636    2.0582    2.2623 ...
    2.4757    2.6984    2.9302    3.1709    3.4205    3.6787 ...
    3.9452    4.2199    4.5024    4.7926    5.0900    5.3945 ...
    5.7055    6.0230    6.3463    6.6753    7.0095    7.3485 ...
    7.6919    8.0393    8.3903    8.7446    9.1016    9.4609 ...
    9.8221   10.1849   10.5487   10.9131   11.2778   11.6423 ...
   12.0061   12.3690   12.7305   13.0903   13.4478   13.8029 ...
   14.1551   14.5041   14.8495   15.1911   15.5285   15.8615 ...
   16.1897   16.5130   16.8310   17.1436   17.4505   17.7516 ...
   18.0466   18.3354   18.6178   18.8938   19.1632   19.4259 ...
   19.6818   19.9308   20.1730   20.4082   20.6364 ...
]'))
assert(~isequal( ...
    round(y_int(:, 1), 4), ...
    [   ...
   48.7780   49.6506   50.5107   51.3608   52.2063   53.0520 ...
   53.9006   54.7535   55.6110   56.4729   57.3389   58.2083 ...
   59.0806   59.9552   60.8312   61.7082   62.5851   63.4614 ...
   64.3358   65.2071   66.0732   66.9308   67.7743   68.5932 ...
   69.3733   70.1028   70.7815   71.4152   72.0089   72.5652 ...
   73.0852   73.5692   74.0168   74.4279   74.8018   75.1380 ...
   75.4362   75.6959   75.9168   76.0984   76.2407   76.3434 ...
   76.4064   76.4298   76.4136   76.3580   76.2633   76.1296 ...
   75.9574   75.7472   75.4995   75.2149   74.8940   74.5376 ...
   74.1464   73.7213   73.2632   72.7730   72.2518   71.7006 ...
   71.1204   70.5125   69.8779   69.2179   68.5337   67.8265 ...
   67.0976   66.3482   65.5797   64.7935   63.9907   63.1727 ...
   62.3408   61.4964   60.6408   59.7752   58.9009   58.0193 ...
   57.1315   56.2388   55.3424   54.4436   53.5433   52.6429 ...
   51.7433   50.8457   49.9510   49.0604   48.1746   47.2947 ...
   46.4215   45.5559   44.6987   43.8505   43.0122   42.1844 ...
   41.3678   40.5628   39.7702   38.9903   38.2236 ...
]'))
assert(~isequal( ...
    round(y_int(:, 2), 4), ...
    [   ...
   49.2857   50.1059   50.9563   51.8322   52.7261   53.6312 ...
   54.5427   55.4570   56.3717   57.2848   58.1944   59.0990 ...
   59.9971   60.8869   61.7673   62.6366   63.4935   64.3368 ...
   65.1655   65.9788   66.7769   67.5610   68.3350   69.1073 ...
   69.8906   70.6947   71.5182   72.3537   73.1946   74.0369 ...
   74.8779   75.7162   76.5506   77.3803   78.2047   79.0232 ...
   79.8353   80.6407   81.4388   82.2292   83.0116   83.7855 ...
   84.5506   85.3066   86.0530   86.7895   87.5157   88.2313 ...
   88.9360   89.6294   90.3112   90.9811   91.6387   92.2837 ...
   92.9159   93.5350   94.1407   94.7328   95.3109   95.8749 ...
   96.4245   96.9595   97.4797   97.9850   98.4751   98.9500 ...
   99.4095   99.8534  100.2817  100.6944  101.0912  101.4723 ...
  101.8375  102.1869  102.5205  102.8383  103.1404  103.4268 ...
  103.6976  103.9530  104.1930  104.4178  104.6276  104.8225 ...
  105.0027  105.1686  105.3201  105.4578  105.5817  105.6921 ...
  105.7894  105.8739  105.9459  106.0056  106.0535  106.0898 ...
  106.1150  106.1294  106.1333  106.1272  106.1114 ...
]'))
