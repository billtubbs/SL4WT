function [model, vars] = gpr_model_setup(data, params)
% [model, vars] = gpr_model_setup(data, params)
% Fits new Gaussian process model to data
%

    % Initialize variables
    vars = struct("significance", params.significance);

    % Fit model to the data provided
    [model, vars] = gpr_model_update([], data, vars, params);

end