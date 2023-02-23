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
n = 5;
sigma_M = 0.1;  % measurement noise
x_d = rand(n, 1)*3;
y_d = f(x_d) + sigma_M*randn(n, 1);

% Fit Gaussian process model
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

param_args = namedargs2cell(params);
gpr_model = fitrgp(x_d, y_d, ...
    param_args{:} ...
);

% Default GPR
% gpr_model = fitrgp(x_d, y_d, ...
%     'KernelFunction', 'squaredexponential' ...
% );

% gpr_model = fitrgp(x_d, y_d, ...
%     'KernelParameters', [1.5; 1], ...
%     'Sigma', 0.1, ...
%     'FitMethod', 'none' ...
% );

% gpr_model = fitrgp(x_d, y_d, ...
%     'KernelParameters', [1.5; 1], ...
%     'Sigma', 0.1, ...
%     'BasisFunction', 'linear', ...
%     'FitMethod', 'none' ...
% );

gpr_model = fitrgp(x_d, y_d, ...
    'KernelParameters', [1.5; 1], ...
    'Sigma', 0.1, ...
    ...'SigmaLowerBound', 0.1, ...
    'ConstantSigma', true, ... 
    'BasisFunction', 'linear' ...
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
y_true = f(x);

% % Plot predictions
% figure(1); clf
% make_stattdplot(Y_pred, Y_pred_int(:, 1), Y_pred_int(:, 2), y_true, x, ...
%    y_d, x_d, "$x$", '$y$', 'prediction', "confidence interval", [0 nan])

