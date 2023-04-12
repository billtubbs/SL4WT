function [y_mean, y_sigma, y_int] = ens_model_predict(models, x, vars, ...
    params)
% [y_mean, y_sigma, x_int] = ens_model_predict(model, x, vars, params)
% Make predictions with an ensemble of models.
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

    n = size(x, 1);
    model_names = fieldnames(models);
    n_models = numel(model_names);
    y_means = nan(n, n_models);
    y_sigmas = nan(n, n_models);
    y_ints = nan(n, 2, n_models);

    switch params.method
        case "bagging"
    
            % Base model name - only one type allowed currently
            base_model_names = string(fieldnames(params.base_models));
            assert(numel(base_model_names) == 1)
            base_model_name = base_model_names(1);
    
            for i = 1:n_models
                model_name = model_names{i};
        
                % Make predictions with each sub-model
                % Note: builtin() is needed here because other code in the
                %   MATLAB workspace overrides the built-in feval function.
                [y_means(:, i), y_sigmas(:, i), y_ints(:, :, i)] = builtin("feval", ...
                        params.base_models.(base_model_name).predictFcn, ...
                        models.(model_name), ...
                        x, ...
                        vars.(model_name), ...
                        params.base_models.(base_model_name).params ...
                    );
            end

        case "boosting"
            error("NotImplementedError")
    
        case "stacking"  % for heterogenous models
    
            for i = 1:n_models
                model_name = model_names{i};
        
                % Make predictions with each sub-model
                % Note: builtin() is needed here because other code in the
                %   MATLAB workspace overrides the built-in feval function.
                [y_means(:, i), y_sigmas(:, i), y_ints(:, :, i)] = builtin("feval", ...
                        params.models.(model_name).predictFcn, ...
                        models.(model_name), ...
                        x, ...
                        vars.(model_name), ...
                        params.models.(model_name).params ...
                    );
            end

    end

    % Make combined predictions, std. dev., and conf. interval
    y_mean = mean(y_means, 2);
    y_sigma = mean(y_sigmas, 2);  %TODO: is this the right way?
    y_int = [min(y_ints(:, 1, :), [], 3) ...
             max(y_ints(:, 2, :), [], 3)];

end