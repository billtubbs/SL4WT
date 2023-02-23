% Test GP model setup, prediction and update functions
%

clear variables

addpath("yaml")
addpath("plot-utils")

test_dir = "tests";
test_data_dir = "data";


%% Test with config file

% Load configuration file
filepath = fullfile(test_dir, test_data_dir, "test_config_gpr.yaml");
config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load initialization file
load load_opt_init.mat

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct
models = struct();
model_vars = struct();
for machine = string(fieldnames(config.machines))'
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

    % Check selected model variables and params
    assert(model.NumObservations == numel(training_data.Load));
    if isfield(model_config.params.fit, 'KernelFunction')
        assert(strcmpi(model.KernelFunction, ...
            model_config.params.fit.KernelFunction))
    end
    if isfield(model_config.params.fit, 'KernelParameters')
        assert(isequal(model.ModelParameters.KernelParameters', ...
            model_config.params.fit.KernelParameters))
    end
    assert(vars.significance == model_config.params.significance)

    % Save for use below
    models.(machine) = model;
    model_vars.(machine) = vars;

end

% Check some more things
model_sigmas = structfun(@(m) m.Sigma, models);
assert(isequal( ...
    round(model_sigmas, 4), ...
    [1.6131    0.6234  115.7473  115.7473  115.7473]' ...
))

% Make predictions with one model
machine = "machine_1";
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

% % Plot predictions and data
% figure(1); clf
% make_statdplot(y_mean, ci(:, 1), ci(:, 2), x, training_data.Power', ...
%     training_data.Load', "Load", "Power")
% p = get(gcf, 'Position');
% set(gcf, 'Position', [p(1:2) 320 210])

% Check outputs
assert(isequal( ...
    round(y_mean, 4), ...
    [50.6408   50.6408   repmat(50.6409, 1, 99)]' ...
))
assert(isequal( ...
    round(y_sigma, 4), ...
    repmat(1.6131, 101, 1) ...
))
assert(isequal( ...
    round(ci, 4), ...
    repmat([47.9876 53.2941], 101, 1) ...
))

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
[models.(machine), vars] = gpr_model_update(models.(machine), ...
    training_data, vars, model_config.params);

% Re-do predictions with model
[y_mean, y_sigma, ci] = gpr_model_predict( ...
    models.(machine), ...
    x, ...
    model_vars.(machine), ...
    model_config ...
);

% % Plot predictions and data
% figure(2); clf
% make_statdplot(y_mean, ci(:, 1), ci(:, 2), x, training_data.Power', ...
%     training_data.Load', "Load", "Power")
% p = get(gcf, 'Position');
% set(gcf, 'Position', [p(1:2) 320 210])

% Check outputs
assert(isequal( ...
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
assert(isequal( ...
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
assert(isequal( ...
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
assert(isequal( ...
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
