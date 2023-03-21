function [model, vars] = gpr_model_update(model, data, vars, params)
% [model, vars] = gpr_model_update(model, data, vars, params)
% Fits new Gaussian process model to data
%

    % Select training data
    X = data{:, params.predictorNames};
    Y = data{:, params.responseNames};

    % Transform inputs and outputs to model input-output space
    if isfield(vars, "inputTransform")
        X = vars.inputTransform.x(X);
    end
    if isfield(vars, "outputTransform")
        Y = vars.outputTransform.y_inv(X, Y);
    end

    % Get any specified fitting parameters
    if isfield(params, "fit")
        param_args = namedargs2cell(params.fit);
    else
        param_args = {};
    end

    % Re-fit GP model to all the data
    model = fitrgp(X, Y, param_args{:});

end