function [c,ceq] = MaxPowerConstraint(x, config)
% [c,ceq] = MaxPowerConstraint(x, config) 
%

global models model_vars curr_iteration

        % TODO: unique is quite a costly compute.  Is it necessary?
        %iterations = length(unique(LOData.Load_Target));

%         if(iterations > curr_iteration && significance >= 0.05 )
%             decay = 0.01 ;
%             significance = significance * (1. / (1+decay * iterations));
%             curr_iteration = iterations;   
%         end

    % Compute model predictions
    machine_names = string(fieldnames(config.machines))';
    n_machines = numel(machine_names);
    y_means = nan(n_machines, 1);
    y_int = nan(n_machines, 2);
    for i = 1:n_machines
        machine = machine_names{i};
        model_name = config.machines.(machine).model;
        model_config = config.models.(model_name);
        [y_means(i), y_sigmas(i), y_int(i, :)] = builtin( ...
            "feval", ...
            model_config.predict_script, ...
            models.(machine), ...
            x(i), ...
            model_vars.(machine), ...
            model_config.params ...
        );
    end

%     % Gaussian Process Optimization in the Bandit Setting paper's bounds           
%     beta_machine1 = sqrt(2 * log(abs(x(1))*iterations^2*pi^2/(6*0.05)));
%     beta_machine2 = sqrt(2 * log(abs(x(2))*iterations^2*pi^2/(6*0.05)));

    % Calculate worst-case maximum power based on model upper
    % confidence intervals and return difference to max power
    % constraint
    % TODO: is the max needed here?  Or is x_ci(:, 2) always > x_ci(:, 1)
    c = sum(max(y_int, [], 2)) - config.simulation.params.PMax;

    ceq = [];
