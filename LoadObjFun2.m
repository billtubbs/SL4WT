function f = LoadObjFun(x, config)
% f = LoadObjFun(x, config)
%

global models model_vars CurrentLoadTarget

    % Compute all model predictions
    machine_names = string(fieldnames(config.machines))';
    n_machines = numel(machine_names);
    y_means = nan(n_machines, 1);
    y_sigmas = nan(n_machines, 1);
    for i = 1:n_machines
        machine = machine_names{i};
        model_name = config.machines.(machine).model;
        model_config = config.models.(model_name);
        [y_means(i), y_sigmas(i), ~] = builtin( ...
            "feval", ...
            model_config.predictFcn, ...
            models.(machine), ...
            x(i), ...
            model_vars.(machine), ...
            model_config.params ...
        );
    end

    % Weights for cost function
    w = config.optimizer.params.w;  % load error vs target
    z = config.optimizer.params.z;  % model uncertainty

    % Compute objective function
    f = sum(y_means).^2 + w .* (sum(x) - CurrentLoadTarget).^2 ...
        - z .* sum(y_sigmas.^2);
