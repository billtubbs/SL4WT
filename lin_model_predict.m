function [y_mean, y_sigma, y_int] = lin_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = lin_model_predict(model, x, vars, params)
% Make predictions with a linear model of the form:
%
%   power = a + b * load 
%

    % Check x is a column vector
    assert(size(x, 2) == 1)

    % Make predictions using model
    [y_mean, y_int] = predict(model, x, 'Alpha', vars.significance);

    % TODO: Is this correct
    y_sigma = model.RMSE .* ones(size(x));  % Std. dev.

end