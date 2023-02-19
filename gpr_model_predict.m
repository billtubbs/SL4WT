function [y_mean, y_sigma, ci] = gpr_model_predict(model, x, vars, params)
% [y_mean, y_sigma, ci] = gpr_model_predict(model, x, vars, params)
% Make predictions with Gaussian process model
%

    [y_mean, y_sigma, ci] = predict( ...
        model, x, 'Alpha', vars.significance);

end