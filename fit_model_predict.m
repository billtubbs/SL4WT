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
% TODO: Include multi-variable models:
%   'poly11': Linear polynomial surface
%   'lowess': Local linear regression (surface)
%
% TODO: Allow custom model types.
%

    % Make predictions using the model
    y_mean = model(x);

    % Calculate confidence intervals - if possible
    switch params.fit.fitType
        case {'poly1', 'poly2', 'poly3'}
            if vars.fit.output.numobs > vars.fit.output.numparam
                level = 1 - vars.significance;
                y_int = predint(model, x, level, 'Functional');
            else
                y_int = nan(size(x, 1), 2);
            end
        otherwise
            y_int = nan(size(x, 1), 2);
    end

    % TODO: Is there a need for sigma estimates?  Yes!
    y_sigma = nan(size(x));

end