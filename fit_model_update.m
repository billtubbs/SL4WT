function [model, vars] = fit_model_update(model, data, vars, params)
% [model, vars] = fit_model_update(model, data, vars, params)
% Fits a model to data using the MATLAB fit function.
% The available models include:
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

    % Fit model
    [model, vars.fit.gof, vars.fit.output] = ...
        fit( ...
            data{:, params.predictorNames}, ...
            data{:, params.responseNames}, ...
            params.fit.fitType ...
        );

end