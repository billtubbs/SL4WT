% Test make_statplot.m, make_statdplot.m and make_stattplot.m

clear all; %close all

addpath("plot-utils")

% Directory to save test plots
plot_dir = 'plots';
if ~isfolder(plot_dir)
    mkdir(plot_dir)
end

rng(0);

% Function to model
f = @(x) sin(x) + 0.25*x + 2;

% Generate data sample
n = 15;
sigma_M = 0.1;  % measurement noise
x_d = rand(n, 1)*3;
y_d = f(x_d) + sigma_M*randn(n, 1);

% Fit hand-tuned Gaussian process model
sigmaL0 = 1.5;  % Length scale for predictors
sigmaF0 = 1;  % Signal standard deviation
sigmaN0 = 0.1;  % Initial noise standard deviation

params = struct();
params.KernelParameters = [sigmaL0; sigmaF0];
params.Sigma = sigmaN0;
params.BasisFunction = 'linear';
%params.Basis = 'linear';
params.FitMethod = 'none';
%params.PredictMethod = 'exact';

% param_args = namedargs2cell(params);
% gpr_model = fitrgp(x_d, y_d, ...
%     param_args{:} ...
% );

% Default GPR
% gpr_model = fitrgp(x_d, y_d);
% assert(strcmp(gpr_model.BasisFunction, 'Constant'))
% assert(strcmp(gpr_model.KernelInformation.Name, 'SquaredExponential'))
% assert(round(gpr_model.Sigma, 4) == 0.0793)
% assert(isequal( ...
%     round(gpr_model.KernelInformation.KernelParameters, 4), ... 
%     [0.8455 0.3874]' ...
% ))

% With no basis function
% gpr_model = fitrgp(x_d, y_d, ...
%     'KernelFunction', 'SquaredExponential', ...
%     'BasisFunction', 'None' ...
% );

% With manually-set Kernel parameters and thus, basis function
% is not fitted
% gpr_model = fitrgp(x_d, y_d, ...
%     'KernelParameters', [1.5; 1], ...
%     'Sigma', 0.1, ...
%     'FitMethod', 'none' ...
% );
% assert(strcmp(gpr_model.BasisFunction, 'Constant'))

% Same as above - basis function has no effect
% gpr_model = fitrgp(x_d, y_d, ...
%     'KernelParameters', [1.5; 1], ...
%     'Sigma', 0.1, ...
%     'BasisFunction', 'linear', ...
%     'FitMethod', 'none' ...
% );
% assert(strcmp(gpr_model.BasisFunction, 'Linear'))

gpr_model = fitrgp(x_d, y_d, ...
    ...'KernelParameters', [1.5; 1], ...
    ...'Sigma', 0.1, ...
    ...'SigmaLowerBound', 0.1, ...
    ...'ConstantSigma', true, ... 
    'BasisFunction', 'Linear' ...
);

% TODO: Doesn't seem possible to fit a Basis Function if
% FitMethod is none.  Or any way to constrain the kernel
% parameters.  I asked a question about this here:
%  https://www.mathworks.com/matlabcentral/answers/1917495-gaussian-process-regression-how-to-fit-a-basis-function-but-not-other-parameters

disp("Basis function:")
fprintf("   Type: %s\n", gpr_model.BasisFunction)
fprintf(" Coeffs: [%s]\n", strjoin(string(gpr_model.Beta), ", "))
disp("Kernel Parameters:")
fprintf(" [sigmaL0 sigmaF0]: [%g, %g]\n", ...
    gpr_model.ModelParameters.KernelParameters)
fprintf("   [sigmaL sigmaF]: [%g, %g]\n", ...
    gpr_model.KernelInformation.KernelParameters)
disp("Measurement noise:")
fprintf(" Sigma0: %g\n", gpr_model.ModelParameters.Sigma)
fprintf("  Sigma: %g\n", gpr_model.Sigma)

% Make new predictions with model
x = linspace(0, 8, 101)';
[Y_pred, ~, Y_pred_int] = predict(gpr_model, x);

% True values
Y_true = f(x);

rmse = sqrt(mean((Y_pred - Y_true).^2));
assert(round(rmse, 4) == 0.6964)

% % Plot predictions
% figure(1); clf
% make_stattdplot(Y_pred, Y_pred_int(:, 1), Y_pred_int(:, 2), y_true, x, ...
%    y_d, x_d, "$x$", '$y$', 'prediction', "confidence interval", [0 nan])
