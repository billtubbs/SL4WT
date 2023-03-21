function [y_mean, y_sigma, y_int] = fp2_model_predict(model, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = fp2_model_predict(model, x, vars, params)
% Make predictions with the first principles model. This model 
% assumes that each machine has a constant efficiency 
% (defined as specific energy consumption kW/kW) which is 
% estimated by taking the average of past observations.
%

    % Transform inputs
    xT = vars.inputTransform.x(x);

    if vars.use_fitted_model

        % Make predictions using model
        [yT_mean, yT_int] = predict(model, xT, 'Alpha', vars.significance);

        % Standard deviation of residuals. This is calculated:
        % residuals = model.Residuals{:, "Raw"};
        % n = model.NumObservations;
        % p = model.NumCoefficients;
        % RMSE = sqrt(sum(residuals.^2) ./ (n - p))
        yT_sigma = model.RMSE .* ones(size(x));

    else

        % Use prior model
        yT_mean = vars.prior.y(xT);
        yT_sigma = vars.prior.y_sigma(xT);
        yT_int = [vars.prior.y_int1(xT) vars.prior.y_int2(xT)];

    end

    % Transform outputs
    y_mean = vars.outputTransform.y(xT, yT_mean);
    y_sigma = vars.outputTransform.y(xT, yT_sigma);  % TODO: is this correct?
    y_int = [vars.outputTransform.y(xT, yT_int(:,1)) ...
             vars.outputTransform.y(xT, yT_int(:,2))];

end