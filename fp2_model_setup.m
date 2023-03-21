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
    vars.inputTransform = struct();
    % Construct functions for input transformation
    vars.inputTransform.x = str2func(params.inputTransform.x);
    vars.inputTransform.x_inv = str2func(params.inputTransform.x_inv);
    vars.outputTransform = struct();
    % Construct functions for output transformation
    vars.outputTransform.y = str2func(params.outputTransform.y);
    vars.outputTransform.y_inv = str2func(params.outputTransform.y_inv);
    vars.prior.y = nan;
    vars.prior.y_sigma = nan;
    vars.prior.y_int1 = nan;
    vars.prior.y_int2 = nan;
    vars.use_fitted_model = false;
    vars.significance = params.significance;

    % Fit model
    [model, vars] = fp2_model_update(model, data, vars, params);

end