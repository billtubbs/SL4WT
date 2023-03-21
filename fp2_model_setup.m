function [model, vars] = fp2_model_setup(data, params)
% [model, vars] = fp2_model_setup(data, params)
% Fits a first principles model to data. This model assumes
% that each machine has a constant efficiency (defined as
% specific energy consumption kW/kW) which is estimated by 
% taking the average of past observations.
%

    % Model object is created by model update function below
    model = struct();

    % Prepare variables struct
    vars = struct();

    % Create functions for input and output transformations
    if isfield(params, "inputTransform")
        vars.inputTransform = create_input_transform(params);
    end
    if isfield(params, "outputTransform")
        vars.outputTransform = create_output_transform(params);
    end

    % These variables will be assigned by the update function below
    vars.prior.y = nan;
    vars.prior.y_sigma = nan;
    vars.prior.y_int1 = nan;
    vars.prior.y_int2 = nan;
    vars.use_fitted_model = false;

    % Significance level used for confidence intervals
    vars.significance = params.significance;

    % Fit model
    [model, vars] = fp2_model_update(model, data, vars, params);

end