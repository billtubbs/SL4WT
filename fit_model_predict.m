function [y_mean, y_sigma, y_int] = fit_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = fit_model_predict(model, x, vars, params)
% Make predictions with a MATLAB fitobj model fitted to 
% data using the fit function. The available models 
% include:
%
%   'poly1': Linear polynomial curve
%   'poly2': Quadratic polynomial curve
%   'poly3': Cubic polynomial curve
%   'linearinterp': Piecewise linear interpolation
%   'cubicinterp': Piecewise cubic interpolation
%   'smoothingspline': Smoothing spline (curve)
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

% TODO: Include multi-variable models:
%   'poly11': Linear polynomial surface
%   'lowess': Local linear regression (surface)
%
% TODO: Allow custom model types.
%
%

    % Make predictions using the model
    y_mean = model(x);

    % Calculate confidence intervals - if possible
    switch params.fit.fitType
        case {'poly1', 'poly2', 'poly3'}
            if vars.fit.output.numobs > vars.fit.output.numparam

                % Confidence level
                level = 1 - vars.significance;

                y_int = predint( ...
                    model,  ...
                    x, ...
                    level, ...
                    'Functional', ... (default: 'Observation')
                    'off' ... (default: 'off')
                );

                % Estimate std. dev.'s from confidence intervals
                sd = norminv(0.5 + level / 2);
                y_sigma = diff(y_int, [], 2) ./ (2 * sd);

            else
                y_int = nan(size(x, 1), 2);
                y_sigma = nan(size(x));
            end

        otherwise
            y_int = nan(size(x, 1), 2);
            y_sigma = nan(size(x));

    end

end