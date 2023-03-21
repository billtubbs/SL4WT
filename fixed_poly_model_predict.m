function [y_mean, y_sigma, y_int] = fixed_poly_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = fixed_poly_model_predict(model, x, vars, params)
% Make predictions with a fixed model based on a specified 
% polynomial function of the form:
%
%   y = a + b * x + c * x^2 + ... 
%
% This is assumed to be a true model and no uncertainty
% estimates or confidence intervals are returned.
%
% Returns
%   y_mean (n, ny) double
%       Expected values of y at each x(i,:), i = 1, 2, ... n.
%   y_sigma (n, ny) double
%       Standard deviations of the uncertainty of the 
%       predictions at each x(i,:), zero in this case.
%   y_int (n, 2*ny) double
%       Lower and upper confidence intervals for each
%       prediction y_mean(i,:). In this case, y_int = [y_mean 
%       y_mean].
%

    % Make predictions using polynomial model
    y_mean = polyval(params.coeff, x);

    % This model is assumed to make perfect predictions (no 
    % uncertainty)
    y_int = [y_mean y_mean];
    y_sigma = zeros(size(x));

end