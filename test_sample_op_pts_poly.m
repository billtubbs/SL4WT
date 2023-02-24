% Test sample_op_pts_poly.m
%

clear variables

addpath("yaml")
rng(0)

test_dir = "tests";
test_data_dir = "data";
filename = "test_sim_config.yaml";
config = yaml.loadFile(fullfile(test_dir, test_data_dir, filename), ...
    "ConvertToArray", true);

% First test with no measurement noise
X = 100;
params = config.machines.("machine_1");
[Y, X_actual] = sample_op_pts_poly(X, params);
assert(round(Y, 4) == 72.3110)
assert(isequal(X, X_actual))

X = [300 400 500]';
params = config.machines.("machine_2");
[Y, X_actual] = sample_op_pts_poly(X, params);
assert(isequal(round(Y, 4), [208.0120  260.3383  320.0089]'))
assert(isequal(X, X_actual))

X = [300 400 500 600 700]';
params = config.machines.("machine_3");
[Y, X_actual] = sample_op_pts_poly(X, params);
assert(isequal(round(Y, 4), [223.8190  276.3440  334.8225  396.4079  454.5696]'))
assert(isequal(X, X_actual))

% Check out of bounds sample
X = [0 200 400 600 800]';
params = config.machines.("machine_4");
[Y, X_actual] = sample_op_pts_poly(X, params);
assert(isequal(round(Y, 4), [173.6489  176.4106  276.3440  396.4079  497.3909]'))
assert(isequal(round(X_actual, 4), [194   200   400   600   795]'))

% Check with measurement noise
X = [0 200 400 600 800]';
sigma_M = 1;
params = config.machines.("machine_5");
[Y, X_actual] = sample_op_pts_poly(X, params, sigma_M);
assert(isequal(round(Y, 4), [174.3637  176.2056  276.2199  397.8976  498.7999]'))
assert(isequal(round(X_actual, 4), [194   200   400   600   795]'))
