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
        [y_means(i), y_sigmas(i), ~] = feval( ...
            model_config.predict_script, ...
            models.(machine), ...
            x(i), ...
            model_vars.(machine), ...
            model_config.params ...
        );
    end

%     total_load = LOData.LoadMachine1(end,1) + ...
%         LOData.LoadMachine2(end,1) + LOData.LoadMachine3(end,1)+ ...
%         LOData.LoadMachine4(end,1) + LOData.LoadMachine5(end,1);
%     is_load_same = LOData.Load_Target(end,1) == LOData.Load_Target(end-1,1) && LOData.Load_Target(end-1,1) == LOData.Load_Target(end-2,1);

%         if (is_load_same && SteadyState ==1 && abs(LOData.Load_Target(end,1) - total_load) < 10)

    z = config.optimizer.params.z;

% %             disp("exploring ")
%             explore_signal = 1;
%         else
%             z = 0;
%             explore_signal = 0;
%         end

    f = sum(y_means).^2 + 1000 * (sum(x) - Current_Load_Target).^2 - z * sum(y_sigmas);
