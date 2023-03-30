function [y_mean, y_sigma, y_int] = gpr_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, ci] = gpr_model_predict(model, x, vars, params)
% Make predictions with Gaussian process model.
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

    % Transform inputs
    if isfield(vars, "inputTransform")
        x = vars.inputTransform.x(x);
    end

    % Make predictions
    [y_mean, y_sigma, y_int] = predict(model, x, 'Alpha', ...
        vars.significance);

    % Transform outputs
    if isfield(vars, "outputTransform")
        y_mean = vars.outputTransform.y(x, y_mean);
        y_sigma = vars.outputTransform.y_sigma(x, y_sigma);
        y_int = [vars.outputTransform.y(x, y_int(:,1)) ...
                 vars.outputTransform.y(x, y_int(:,2))];
    end

end