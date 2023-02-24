function [model, vars] = fit_model_setup(data, params)
% [model, vars] = fit_model_setup(data, params)
% Creates model that can be fitted to data using the 
% MATLAB fit function.  The available models 
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

    % Initialize variables
    vars = struct("significance", params.significance);

    % Fit model to the data provided
    [model, vars] = fit_model_update([], data, vars, params);

end