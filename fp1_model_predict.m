function [y_mean, y_sigma, y_int] = fp1_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = fp1_model_predict(model, x, vars, params)
% Make predictions with the first principles model. This model 
% assumes that each machine has a constant efficiency 
% (defined as specific energy consumption kW/kW) which is 
% estimated by taking the average of past observations.
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
    y_mean = vars.specific_energy .* x;
    y_sigma = vars.se_sigma .* x;
    y_int = vars.se_int .* x;

end