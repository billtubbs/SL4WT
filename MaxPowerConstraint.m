function [c,ceq] = MaxPowerConstraint(x, config)
% [c,ceq] = MaxPowerConstraint(x, config) 
%

global  LOData models model_vars curr_iteration

        % TODO: unique is quite a costly compute.  Is it necessary?
        %iterations = length(unique(LOData.Load_Target));

%         if(iterations > curr_iteration && significance >= 0.05 )
%             decay = 0.01 ;
%             significance = significance * (1. / (1+decay * iterations));
%             curr_iteration = iterations;   
%         end

    % Compute model predictions
    n_machines = numel(config.machines.names);
    y_means = nan(n_machines, 1);
    x_ci = nan(n_machines, 2);
    for i = 1:n_machines
        machine = config.machines.names{i};
        model_name = config.machines.(machine).model;
        model_config = config.models.(model_name);
        [y_means(i), ~, x_ci(i, :)] = gpr_model_predict( ...
            models.(machine), x(i), model_vars.(machine), model_config);
    end

    % Previous code that was commented-out
    %[mean_machine_1,~,PowerPred_Int_machine1] = predict(gprMdlLP_machine1,x(1), 'Alpha', significance); 
    %[mean_machine_2,~,PowerPred_Int_machine2] = predict(gprMdlLP_machine2,x(2), 'Alpha', significance);
    %[mean_machine_3,~,PowerPred_Int_machine3] = predict(gprMdlLP_machine3,x(3), 'Alpha', significance);
    %[mean_machine_4,~,PowerPred_Int_machine4] = predict(gprMdlLP_machine4,x(4), 'Alpha', significance);
    %[mean_machine_5,~,PowerPred_Int_machine5] = predict(gprMdlLP_machine5,x(5), 'Alpha', significance);
    %c(1) = max(PowerPred_Int_machine1) + max(PowerPred_Int_machine2) + ...
    %    max(PowerPred_Int_machine3) + max(PowerPred_Int_machine4) + ...
    %    max(PowerPred_Int_machine5) - PMax;
% 
%     % Gaussian Process Optimization in the Bandit Setting paper's bounds           
%     beta_machine1 = sqrt(2 * log(abs(x(1))*iterations^2*pi^2/(6*0.05)));
%     beta_machine2 = sqrt(2 * log(abs(x(2))*iterations^2*pi^2/(6*0.05)));

    % Calculate worst-case maximum power based on model upper
    % confidence intervals and return difference to max power
    % constraint
    % TODO: is the max needed here?  Or is x_ci(:, 2) always > x_ci(:, 1)
    c(1) = sum(max(x_ci,[],2)) - config.simulation.params.PMax;

    ceq = [];
