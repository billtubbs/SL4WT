function f = LoadObjFun(x, config)
% f = LoadObjFun(x, config)
%

global models model_vars Current_Load_Target

    % Compute model predictions
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
            model_config.predict_script, ...
            models.(machine), ...
            x(i), ...
            model_vars.(machine), ...
            model_config.params ...
        );
    end

    % Weight on model uncertainty
    z = config.optimizer.params.z;

    % Compute objective function
    f = sum(y_means).^2 + 1000 * (sum(x) - Current_Load_Target).^2 - z * sum(y_sigmas);
