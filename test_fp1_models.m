% Test fp1 model setup, prediction and update functions
%

clear variables

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";


%% Test initialization and prediction without data 

params = struct();
params.prior.se_sigma = 1;
params.prior.specific_energy = 0.7;
params.prior.se_int = [0.5 0.9];
params.significance = 0.1;

data = struct();
data.Load = double.empty(0, 1);
data.Power = double.empty(0, 1);

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


%% Test initialization with data

params = struct();
params.prior.se_sigma = 1;
params.prior.specific_energy = 0.7;
params.prior.se_int = [0.5 0.9];
params.significance = 0.1;

data = struct();
data.Load = [50 100 150];
data.Power = [35.05 70.18 104.77];

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

% Load initialization file
load load_opt_init.mat

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct
models = struct();
model_vars = struct();

% Test results to compare to
specific_energy_chk = [
    0.858096
    0.772222
    0.760602
    0.760602
    0.760602
];
se_sigma_chk = [
    0.024607 
    0.003620 
    0.190573 
    0.190573 
    0.190573
];
se_int_chk = [
    0.748237 0.967956
    0.756061 0.788382
    -0.090211 1.611415
    -0.090211 1.611415
    -0.090211 1.611415
];

machine_names = string(fieldnames(config.machines))';
for i = 1:numel(machine_names)
    machine = machine_names(i);
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
    %fprintf("%.6f\n", vars.se_sigma)

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
training_data = config.training.data.(machine);
op_limits = config.machines.(machine).op_limits;
model = config.machines.(machine).model;
model_config = config.models.(model);
x = linspace(op_limits(1), op_limits(2), 101)';
[y_mean, y_sigma, ci] = fp1_model_predict( ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config ...
);

% Plot predictions and data
figure(1); clf
make_statdplot(y_mean, ci(:, 1), ci(:, 2), x, training_data.Power', ...
    training_data.Load', "Load", "Power")
p = get(gcf, 'Position');
set(gcf, 'Position', [p(1:2) 320 210])

% Check outputs
% Use this command to find these values:
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_mean)
assert(isequal( ...
    round(y_mean, 4), [
   48.0534    49.4607    50.8680    52.2752    53.6825    55.0898 ...
   56.4971    57.9043    59.3116    60.7189    62.1262    63.5335 ...
   64.9407    66.3480    67.7553    69.1626    70.5698    71.9771 ...
   73.3844    74.7917    76.1990    77.6062    79.0135    80.4208 ...
   81.8281    83.2353    84.6426    86.0499    87.4572    88.8645 ...
   90.2717    91.6790    93.0863    94.4936    95.9009    97.3081 ...
   98.7154   100.1227   101.5300   102.9372   104.3445   105.7518 ...
  107.1591   108.5664   109.9736   111.3809   112.7882   114.1955 ...
  115.6027   117.0100   118.4173   119.8246   121.2319   122.6391 ...
  124.0464   125.4537   126.8610   128.2682   129.6755   131.0828 ...
  132.4901   133.8974   135.3046   136.7119   138.1192   139.5265 ...
  140.9337   142.3410   143.7483   145.1556   146.5629   147.9701 ...
  149.3774   150.7847   152.1920   153.5993   155.0065   156.4138 ...
  157.8211   159.2284   160.6356   162.0429   163.4502   164.8575 ...
  166.2648   167.6720   169.0793   170.4866   171.8939   173.3011 ...
  174.7084   176.1157   177.5230   178.9303   180.3375   181.7448 ...
  183.1521   184.5594   185.9666   187.3739   188.7812 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", y_sigma)
assert(isequal( ...
    round(y_sigma, 4), [ ...
    1.3780     1.4184     1.4587     1.4991     1.5394     1.5798 ...
    1.6202     1.6605     1.7009     1.7412     1.7816     1.8219 ...
    1.8623     1.9026     1.9430     1.9834     2.0237     2.0641 ...
    2.1044     2.1448     2.1851     2.2255     2.2658     2.3062 ...
    2.3466     2.3869     2.4273     2.4676     2.5080     2.5483 ...
    2.5887     2.6291     2.6694     2.7098     2.7501     2.7905 ...
    2.8308     2.8712     2.9115     2.9519     2.9923     3.0326 ...
    3.0730     3.1133     3.1537     3.1940     3.2344     3.2748 ...
    3.3151     3.3555     3.3958     3.4362     3.4765     3.5169 ...
    3.5572     3.5976     3.6380     3.6783     3.7187     3.7590 ...
    3.7994     3.8397     3.8801     3.9205     3.9608     4.0012 ...
    4.0415     4.0819     4.1222     4.1626     4.2029     4.2433 ...
    4.2837     4.3240     4.3644     4.4047     4.4451     4.4854 ...
    4.5258     4.5661     4.6065     4.6469     4.6872     4.7276 ...
    4.7679     4.8083     4.8486     4.8890     4.9294     4.9697 ...
    5.0101     5.0504     5.0908     5.1311     5.1715     5.2118 ...
    5.2522     5.2926     5.3329     5.3733     5.4136 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", ci(:, 1))
assert(isequal( ...
    round(ci(:, 1), 4), [ ...
   41.9013    43.1284    44.3555    45.5826    46.8097    48.0368 ...
   49.2639    50.4910    51.7181    52.9452    54.1723    55.3994 ...
   56.6266    57.8537    59.0808    60.3079    61.5350    62.7621 ...
   63.9892    65.2163    66.4434    67.6705    68.8976    70.1247 ...
   71.3519    72.5790    73.8061    75.0332    76.2603    77.4874 ...
   78.7145    79.9416    81.1687    82.3958    83.6229    84.8500 ...
   86.0772    87.3043    88.5314    89.7585    90.9856    92.2127 ...
   93.4398    94.6669    95.8940    97.1211    98.3482    99.5753 ...
  100.8025   102.0296   103.2567   104.4838   105.7109   106.9380 ...
  108.1651   109.3922   110.6193   111.8464   113.0735   114.3006 ...
  115.5278   116.7549   117.9820   119.2091   120.4362   121.6633 ...
  122.8904   124.1175   125.3446   126.5717   127.7988   129.0259 ...
  130.2531   131.4802   132.7073   133.9344   135.1615   136.3886 ...
  137.6157   138.8428   140.0699   141.2970   142.5241   143.7512 ...
  144.9784   146.2055   147.4326   148.6597   149.8868   151.1139 ...
  152.3410   153.5681   154.7952   156.0223   157.2494   158.4765 ...
  159.7037   160.9308   162.1579   163.3850   164.6121 ...
]'))
% fprintf("%10.4f %10.4f %10.4f %10.4f %10.4f %10.4f ...\n", ci(:, 2))
assert(isequal( ...
    round(ci(:, 2), 4), [ ...
   54.2055    55.7930    57.3804    58.9679    60.5553    62.1428 ...
   63.7302    65.3177    66.9051    68.4926    70.0800    71.6675 ...
   73.2549    74.8424    76.4298    78.0173    79.6047    81.1921 ...
   82.7796    84.3670    85.9545    87.5419    89.1294    90.7168 ...
   92.3043    93.8917    95.4792    97.0666    98.6541   100.2415 ...
  101.8290   103.4164   105.0039   106.5913   108.1788   109.7662 ...
  111.3537   112.9411   114.5286   116.1160   117.7034   119.2909 ...
  120.8783   122.4658   124.0532   125.6407   127.2281   128.8156 ...
  130.4030   131.9905   133.5779   135.1654   136.7528   138.3403 ...
  139.9277   141.5152   143.1026   144.6901   146.2775   147.8650 ...
  149.4524   151.0399   152.6273   154.2147   155.8022   157.3896 ...
  158.9771   160.5645   162.1520   163.7394   165.3269   166.9143 ...
  168.5018   170.0892   171.6767   173.2641   174.8516   176.4390 ...
  178.0265   179.6139   181.2014   182.7888   184.3763   185.9637 ...
  187.5512   189.1386   190.7260   192.3135   193.9009   195.4884 ...
  197.0758   198.6633   200.2507   201.8382   203.4256   205.0131 ...
  206.6005   208.1880   209.7754   211.3629   212.9503 ...
]'))

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
training_data = config.training.data.(machine);
training_data.Load = [training_data.Load io_data(9, 1)];
training_data.Power = [training_data.Power io_data(9, 2)];

% Test update function (trivial for GPs)
[models.(machine), vars] = fp1_model_update(models.(machine), ...
    training_data, vars, model_config.params);

% Check vars updated
assert(vars.significance == model_config.params.significance)
assert(round(vars.specific_energy, 6) ~= specific_energy_chk(1))
assert(round(vars.specific_energy, 6) == 0.815794)
assert(round(vars.se_sigma, 6) ~= se_sigma_chk(1))
assert(round(vars.se_sigma, 6), 0.075308)
assert(~isequal(round(vars.se_int, 6), se_int_chk(1, :)))
assert(isequal(round(vars.se_int, 6), [0.688835  0.942752]))

% Re-do predictions with model
[y_mean, y_sigma, ci] = fp1_model_predict( ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config ...
);

% Plot predictions and data
figure(2); clf
make_statdplot(y_mean, ci(:, 1), ci(:, 2), x, training_data.Power', ...
    training_data.Load', "Load", "Power")
p = get(gcf, 'Position');
set(gcf, 'Position', [p(1:2) 320 210])

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
    round(ci(:, 1), 4), ...
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
    round(ci(:, 2), 4), ...
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