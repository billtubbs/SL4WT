function f = LoadObjFun(x, config)
%global Current_Load_Target gprMdlLP_machine1 gprMdlLP_machine2 ...
%    SteadyState significance LOData explore_signal gprMdlLP_machine3 ...
%    gprMdlLP_machine4 gprMdlLP_machine5
global LOData LOModelData models curr_iteration Current_Load_Target

    % Compute model predictions
    n_machines = numel(config.machines.names);
    y_means = nan(1, n_machines);
    y_sigmas = nan(1, n_machines);
    for i = 1:n_machines
        machine = config.machines.names{i};
        model_name = config.machines.(machine).model;
        model_config = config.models.(model_name);
        [y_means(i), y_sigmas(i), ~] = gpr_model_predict( ...
            models.(machine), x(i), model_config);
    end

%        total_load = LOData.LoadMachine1(end,1) + ...
%            LOData.LoadMachine2(end,1) + LOData.LoadMachine3(end,1)+ ...
%            LOData.LoadMachine4(end,1) + LOData.LoadMachine5(end,1);
%         is_load_same = LOData.Load_Target(end,1) == LOData.Load_Target(end-1,1) && LOData.Load_Target(end-1,1) == LOData.Load_Target(end-2,1);

%         if (is_load_same && SteadyState ==1 && abs(LOData.Load_Target(end,1) - total_load) < 10)

            z = 1000;

% %             disp("exploring ")
%             explore_signal = 1;
%         else
%             z = 0;
%             explore_signal = 0;
%         end

%        f = (mean_machine1 + mean_machine2 + mean_machine3 + mean_machine4 + mean_machine5)^2 ...
%            + 0*(x(1) + x(2) + x(3) + x(4) + x(5) - Current_Load_Target)^2 ...
%            - 0*(sigma_machine1 + sigma_machine2 + sigma_machine3 + sigma_machine4 + sigma_machine5);
         f = sum(y_means).^2 + 1000 * (sum(x) - Current_Load_Target).^2 - z * sum(y_sigmas);

