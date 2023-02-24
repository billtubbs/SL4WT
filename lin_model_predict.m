function [y_mean, y_sigma, y_int] = lin_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = lin_model_predict(model, x, vars, params)
% Make predictions with a linear model of the form:
%
%   power = a + b * load 
%

    % Make predictions using model
    [y_mean, y_int] = predict(model, x, 'Alpha', vars.significance);

    % TODO: Is there a need for sigma estimates?
    y_sigma = nan(size(x));

end