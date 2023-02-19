function [model, vars] = gpr_model_setup(data, params)
% [model, vars] = gpr_model_setup(data, params)
% Fits new Gaussian process model to data
%

    vars = struct("significance", params.significance);
    [model, vars] = gpr_model_update([], data, vars, params);

end