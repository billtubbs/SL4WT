function [model, vars] = fp2_model_update(model, data, vars, params)
% [model, vars] = fp2_model_update(model, data, vars, params)
% Updates the first principles model to the data. This model 
% assumes that each machine has a constant efficiency 
% (defined as specific energy consumption kW/kW) which is 
% estimated by taking the average of past observations.
%

    % Select training data
    X = data{:, params.predictorNames};
    Y = data{:, params.responseNames};

    % Number of data points
    n = size(X, 1);

    % Default prior model
    vars.prior.y = str2func(params.prior.y);
    vars.prior.y_sigma = str2func(params.prior.y_sigma);
    vars.prior.y_int1 = str2func(params.prior.y_int1);
    vars.prior.y_int2 = str2func(params.prior.y_int2);

    vars.use_fitted_model = false;
    if n > 0

        % Transform inputs and outputs to model input-output space
        if isfield(vars, "inputTransform")
            X = vars.inputTransform.x(X);
        end
        if isfield(vars, "outputTransform")
            Y = vars.outputTransform.y_inv(X, Y);
        end

        % Horizontal line (zero order) prior
        y_mean = mean(Y);

        if n > 1

            % Fit linear model
            model = fitlm(X, Y);

            % Check significance
            % TODO: How best to do this?
            if model.anova.F(1) >= 4
                vars.use_fitted_model = true;
            end

            % Fixed std. deviation for prior
            y_sigma = std(Y);
            vars.prior.y_sigma = @(x) y_sigma .* ones(size(x));

            % Fixed confidence interval for prior
            intervals = [0.5.*vars.significance 1-0.5.*vars.significance];
            se = y_sigma ./ sqrt(n);  % standard error
            ts = tinv(intervals, n - 1);  % T-Score
            y_int = y_mean + ts .* se;
            vars.prior.y_int1 = @(x) y_int(1) .* ones(size(x));
            vars.prior.y_int2 = @(x) y_int(2) .* ones(size(x));

        end

        % Prior based on mean of Y (zero order)
        vars.prior.y = @(x) y_mean .* ones(size(x));

    end

end