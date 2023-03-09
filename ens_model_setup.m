function [models, vars] = ens_model_setup(data, params)
% [model, vars] = ens_model_setup(data, params)
% Creates an ensemble model which is a collection of
% models that are fitted to the data and used for
% prediction.
%

    models = struct();

    for model = string(fieldnames(params.models))'

        % Create each sub-model
        [models.(model), vars.(model)] = feval( ...
            params.models.(model).setupFcn, ...
            data, ...
            params.models.(model).params ...
        );

    end

end