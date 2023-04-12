function [models, vars] = ens_model_update(models, data, vars, params)
% [models, vars] = ens_model_update(models, data, vars, params)
% Fits an ensemble of models to the data.
%

    switch params.method
        case "bagging"

            % Base model name - only one type allowed currently
            base_model_names = string(fieldnames(params.base_models));
            assert(numel(base_model_names) == 1)
            base_model_name = base_model_names(1);
        
            for model_name = string(fieldnames(models))'
        
                % Fit each sub-model
                [models.(model_name), vars.(model_name)] = feval( ...
                        params.base_models.(base_model_name).updateFcn, ...
                        models.(model_name), ...
                        data, ...
                        vars.(model_name), ...
                        params.base_models.(base_model_name).params ...
                    );
        
            end

        case "boosting"
            error("NotImplementedError")

        case "stacking"  % for heterogenous models

            for model_name = string(fieldnames(models))'
        
                % Fit each sub-model
                [models.(model_name), vars.(model_name)] = feval( ...
                        params.models.(model_name).updateFcn, ...
                        models.(model_name), ...
                        data, ...
                        vars.(model_name), ...
                        params.models.(model_name).params ...
                    );
        
            end

    end

end