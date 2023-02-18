function [y_mean, y_sigma, x] = gpr_model_predict(model, x, config)
% model = gpr_model_predict(model, x, config)
% Make predictions with Gaussian process model
%
global significance

    [y_mean, y_sigma, x] = predict( ...
        model, x, 'Alpha', significance);

end