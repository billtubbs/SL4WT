function [y_mean, y_sigma, y_int] = fp1_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = fp1_model_predict(model, x, vars, params)
% Make predictions with the first principles model. This model 
% assumes that each machine has a constant efficiency 
% (defined as specific energy consumption kW/kW) which is 
% estimated by taking the average of past observations.
%

    % Check x is a column vector
    assert(size(x, 2) == 1)

    % Make predictions using model
    y_mean = vars.specific_energy .* x;
    y_sigma = vars.se_sigma .* x;
    y_int = vars.se_int .* x;

end