function [y_mean, y_sigma, y_int] = fixed_poly_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = fixed_poly_model_predict(model, x, vars, params)
% Make predictions with a fixed model based on a specified 
% polynomial function of the form:
%
%   y = a + b * x + c * x^2 + ... 
%

    % Make predictions using polynomial model
    y_mean = polyval(params.coeff, x);

    % This model is assumed to make perfect predictions (no 
    % uncertainty)
    y_int = [y_mean y_mean];
    y_sigma = zeros(size(x));

end