function [model, vars] = gpr_model_setup(data, params)
% [model, vars] = gpr_model_setup(data, params)
% Fits new Gaussian process model to data
%

    % Initialize variables
    vars = struct("significance", params.significance);

    % Create functions for input and output transformations
    if isfield(params, "inputTransform")
        vars.inputTransform = create_input_transform(params);
    end
    if isfield(params, "outputTransform")
        vars.outputTransform = create_output_transform(params);
    end

    % Fit model to the data provided
    [model, vars] = gpr_model_update([], data, vars, params);

end