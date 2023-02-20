function [model, vars] = gpr_model_update(model, data, vars, params)
% [model, vars] = gpr_model_update(model, data, vars, params)
% Fits new Gaussian process model to data
%

    % For a GP model, simply re-fit to all the data
    model = fitrgp( ...
        data.Load, data.Power, ...
        'KernelFunction', params.KernelFunction, ...
        'KernelParameters', params.KernelParameters' ...
    );

    % TODO: What vars need updating during an update?

end