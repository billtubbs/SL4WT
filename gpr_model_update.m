function [model, vars] = gpr_model_update(model, data, vars, params)
% [model, vars] = gpr_model_update(model, data, vars, params)
% Fits new Gaussian process model to data
%

    % For a GP model, simply re-fit to all the data
    param_args = namedargs2cell(params.fit);
    model = fitrgp( ...
        data{:, params.predictorNames}, ...
        data{:, params.responseNames}, ...
        param_args{:} ...
    );

    % TODO: What vars need updating during an update?

end