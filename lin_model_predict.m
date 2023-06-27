function [y_mean, y_sigma, y_int] = lin_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = lin_model_predict(model, x, vars, params)
% Make predictions with a linear model of the form:
%
%   y_mean = a + b * x
%
% Returns
%   y_mean (n, ny) double
%       Expected values of y at each x(i,:), i = 1, 2, ... n.
%   y_sigma (n, ny) double
%       Standard deviations of the uncertainty of the 
%       predictions y_mean(i,:) at each x(i,:).
%   y_int (n, 2*ny) double
%       Lower and upper confidence intervals for each
%       prediction y_mean(i,:). The first 1:n columns are
%       the lower bounds, columns n+1:2*n are the upper
%       bounds.
%

    % Make predictions using model
    [y_mean, y_int] = predict( ...
        model, ...
        x, ...
        'Alpha', vars.significance, ...
        'Prediction', 'curve', ... (default: 'curve')
        'Simultaneous', false ... (default: false)
    );

    % Standard deviation of residuals is calculated as follows:
    % residuals = model.Residuals{:, "Raw"};
    % n = model.NumObservations;
    % p = model.NumCoefficients;
    % RMSE = sqrt(sum(residuals.^2) ./ (n - p))
    % assert(abs(model.RMSE - RMSE) < 1e-10)

    % Confidence intervals are calculated as follows
    % TODO: Check calculations

    % Estimate std. dev. from confidence intervals
    sd = norminv(0.5 + (1 - vars.significance) / 2);
    y_sigma = diff(y_int, [], 2) ./ (2 * sd);

end