% Test fp1 model functions

params = struct();
params.prior.y_sigma = 1;
params.prior.specific_energy = 0.7;
params.prior.significance = 0.1;
params.prior.se_int = [0.5 0.9];

% Test initialization without data
data = struct();
data.Load = double.empty(0, 1);
data.Power = double.empty(0, 1);
[model, vars] = fp1_model_setup(data, params);

% Test predictions with input vector
x = [50 100 150 200]';
[y_mean, y_sigma, y_int] = fp1_model_predict(model, x, vars, params);

assert(isequal(y_mean, [35 70 105 140]'))
assert(isequal(y_sigma, [1 1 1 1]'))
assert(isequal(y_int, [ ...
    25    45
    50    90
    75   135
   100   180
]))

data = struct();
data.Load = [50 100 150];
data.Power = [35.05 70.18  104.77];

% Test initialization with data
[model, vars] = fp1_model_setup(data, params);

specific_energy = data.Power ./ data.Load;
assert(isequal(fieldnames(vars), {'significance', ...
    'specific_energy', 'y_sigma', 'se_int'}'))
assert(vars.specific_energy == mean(specific_energy));
assert(vars.y_sigma == var(specific_energy));

% Test predictions with single point
x = 200;
[y_mean, y_sigma, y_int] = fp1_model_predict(model, x, vars, params);

assert(y_mean == mean(specific_energy) .* x);
assert(y_sigma == var(specific_energy));

% Calculate confidence interval
intervals = [0.5.*vars.significance 1-0.5.*vars.significance];
n = length(specific_energy);
se = std(specific_energy) ./ sqrt(n);  % Standard Error
ts = tinv(intervals, n - 1);  % T-Score
y_int_calc = (vars.specific_energy + ts .* se) .* x;
assert(isequal(y_int_calc, y_int));
