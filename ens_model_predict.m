function [y_mean, y_sigma, y_int] = ens_model_predict(models, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = ens_model_predict(model, x, vars, params)
% Make predictions with an ensemble of models.
%

    n = size(x, 1);
    model_names = fieldnames(models);
    n_models = numel(model_names);
    y_means = nan(n, n_models);
    y_sigmas = nan(n, n_models);
    y_ints = nan(n, 2, n_models);

    for i = 1:n_models
        model_name = model_names{i};

        % Make predictions with each sub-model
        % Note: builtin() is needed here because other code in the
        %   MATLAB workspace overrides the built-in feval function.
        [y_means(:, i), y_sigmas(:, i), y_ints(:, :, i)] = builtin("feval", ...
                params.models.(model_name).predict_script, ...
                models.(model_name), ...
                x, ...
                vars.(model_name), ...
                params.models.(model_name).params ...
            );

    end

    % Make combined predictions, std. dev., and conf. interval
    y_mean = mean(y_means, 2);
    y_sigma = nan(n, 1);  % TODO: Not implemented yet
    y_int = [min(y_ints(:, 1), 3) max(y_ints(:, 2), 3)];

end