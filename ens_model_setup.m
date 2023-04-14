function [models, vars] = ens_model_setup(data, params)
% [model, vars] = ens_model_setup(data, params)
% Creates an ensemble model predictor based on the bagging
% method (bootstrap aggregation). Ensemble models involve
% fitting a collection of models to subsets of the data
% and combining (e.g. by averaging) the predictions.
%

    models = struct();

    % Initialize variables
    vars = struct("significance", params.significance);

    switch params.method
        case "bagging"

            for i = 1:params.n_estimators

                % Base model name - only one type allowed currently
                base_model_names = string(fieldnames(params.base_models));
                assert(numel(base_model_names) == 1)
                base_model_name = base_model_names(1);

                % Randomly select a subset of the data
                n_pts = size(data, 1);
                n_sub = floor(n_pts * params.max_samples);
                i_sub = randperm(n_pts, n_sub);

                % Fit sub-model to subset of data
                fmt = strcat( ...
                    "m%0", ...
                    sprintf("%d", floor(log10(params.n_estimators)) + 1), ...
                    "d" ...
                );
                name = sprintf(fmt, i);
                [models.(name), vars.(name)] = feval( ...
                    params.base_models.(base_model_name).setupFcn, ...
                    data(i_sub, :), ...
                    params.base_models.(base_model_name).params ...
                );

            end

        case "boosting"
            error("NotImplementedError")

        case "stacking"  % for heterogenous models

            for model = string(fieldnames(params.models))'

                % Create each sub-model
                [models.(model), vars.(model)] = feval( ...
                    params.models.(model).setupFcn, ...
                    data, ...
                    params.models.(model).params ...
                );
        
            end
    end

end