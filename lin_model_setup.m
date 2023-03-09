function [model, vars] = lin_model_setup(data, params)
% [model, vars] = lin_model_setup(data, params)
% Creates a linear model of the form:
%
%     power = a + b * load 
%
% fitted to past observations.
%

    assert(size(data{:, params.predictorNames}, 1) > 1, ...
        "Not enough data to fit model")

    % Initialize variables
    vars = struct("significance", params.significance);

    % Fit model to the data provided
    [model, vars] = lin_model_update([], data, vars, params);

end