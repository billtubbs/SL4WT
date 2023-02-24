function [models, vars] = ens_model_update(models, data, vars, params)
% [models, vars] = ens_model_update(models, data, vars, params)
% Fits an ensemble of models to the data.
%

    for model = string(fieldnames(models))'

        % Fit each sub-model
        [models.(model), vars.(model)] = feval( ...
                params.models.(model).update_script, ...
                data, ...
                vars.(model), ...
                params.(model) ...
            );

    end

end