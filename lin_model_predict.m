function [y_mean, y_sigma, y_int] = lin_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = lin_model_predict(model, x, vars, params)
% Make predictions with a linear model of the form:
%
%   power = a + b * load 
%

    % Make predictions using model
    [y_mean, y_int] = predict(model, x, 'Alpha', vars.significance);

    % Standard deviation of residuals. This is calculated:
    % residuals = model.Residuals{:, "Raw"};
    % n = model.NumObservations;
    % p = model.NumCoefficients;
    % RMSE = sqrt(sum(residuals.^2) ./ (n - p))
    y_sigma = model.RMSE .* ones(size(x));

end