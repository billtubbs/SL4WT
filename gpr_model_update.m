function [model, vars] = gpr_model_update(model, data, vars, params)
% [model, vars] = gpr_model_update(model, data, vars, params)
% Fits new Gaussian process model to data
%

    % Note: data vectors must be in columns for fitrgp
    assert(size(data.Load, 1) == 1)
    assert(size(data.Power, 1) == 1)

    % For a GP model, simply re-fit to all the data
    param_args = namedargs2cell(params.fit);
    model = fitrgp( ...
        data.Load', data.Power', ...
        param_args{:} ...
    );

    % TODO: What vars need updating during an update?

end