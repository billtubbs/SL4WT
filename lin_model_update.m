function [model, vars] = lin_model_update(model, data, vars, params)
% [model, vars] = lin_model_update(model, data, vars, params)
% Fits a linear model of the form:
%
%     power = a + b * load 
%
% to past observations.
%

    % Fit linear model
    model = fitlm(data.Load, data.Power);

end