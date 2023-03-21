function [y_mean, y_sigma, y_int] = fp2_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = fp2_model_predict(model, x, vars, params)
% Make predictions with the first principles model. This model 
% assumes that each machine has a constant efficiency 
% (defined as specific energy consumption kW/kW) which is 
% estimated by taking the average of past observations.
%
% Returns
%   y_mean (n, ny) double
%       Expected values of y at each x(i,:), i = 1, 2, ... n.
%   y_sigma (n, ny) double
%       Standard deviations of the uncertainty of the 
%       predictions y_mean(i,:) at each x(i,:).
%   y_int (n, 2*ny) double
%       Lower and upper confidence intervals for each
%       prediction y_mean(i,:). The first 1:n columns are
%       the lower bounds, columns n+1:2*n are the upper
%       bounds.
%

    % Transform inputs
    if isfield(vars, "inputTransform")
        x = vars.inputTransform.x(x);
    end

    if vars.use_fitted_model

        % Make predictions using model
        [y_mean, y_int] = predict(model, x, 'Alpha', vars.significance);

        % Standard deviation of residuals. This is calculated:
        % residuals = model.Residuals{:, "Raw"};
        % n = model.NumObservations;
        % p = model.NumCoefficients;
        % RMSE = sqrt(sum(residuals.^2) ./ (n - p))
        y_sigma = model.RMSE .* ones(size(x));

    else

        % Use prior model
        y_mean = vars.prior.y(x);
        y_sigma = vars.prior.y_sigma(x);
        y_int = [vars.prior.y_int1(x) vars.prior.y_int2(x)];

    end

    % Transform outputs
    if isfield(vars, "outputTransform")
        y_mean = vars.outputTransform.y(x, y_mean);
        y_sigma = vars.outputTransform.y(x, y_sigma);  % TODO: is this correct?
        y_int = [vars.outputTransform.y(x, y_int(:,1)) ...
                 vars.outputTransform.y(x, y_int(:,2))];
    end

end