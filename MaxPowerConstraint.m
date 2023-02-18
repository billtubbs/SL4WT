function [c,ceq] = MaxPowerConstraint(x, config) 
global  LOData models curr_iteration significance

        % TODO: unique is quite a costly compute.  Is it necessary?
        iterations = length(unique(LOData.Load_Target));

        if(iterations > curr_iteration && significance >= 0.05 )
            decay = 0.01 ;
            significance = significance * (1. / (1+decay * iterations));
            curr_iteration = iterations;   
        end

        % Compute model predictions
        %TODO: Shouldn't have to do this twice, here and in obj. func.
        n_machines = numel(config.machines.names);
        y_means = nan(1, n_machines);
        y_sigmas = nan(1, n_machines);
        pred_ints = nan(1, n_machines);
        for i = 1:n_machines
            machine = config.machines.names{i};
            model_name = config.machines.(machine).model;
            model_config = config.models.(model_name);
            [y_means(i), y_sigmas(i), pred_ints(i)] = gpr_model_predict( ...
                models.(machine), x(i), model_config);
        end

        %[mean_machine_1,~,PowerPred_Int_machine1] = predict(gprMdlLP_machine1,x(1), 'Alpha', significance); 
        %[mean_machine_2,~,PowerPred_Int_machine2] = predict(gprMdlLP_machine2,x(2), 'Alpha', significance);
        %[mean_machine_3,~,PowerPred_Int_machine3] = predict(gprMdlLP_machine3,x(3), 'Alpha', significance);
        %[mean_machine_4,~,PowerPred_Int_machine4] = predict(gprMdlLP_machine4,x(4), 'Alpha', significance);
        %[mean_machine_5,~,PowerPred_Int_machine5] = predict(gprMdlLP_machine5,x(5), 'Alpha', significance);
        %c(1) = max(PowerPred_Int_machine1) + max(PowerPred_Int_machine2) + ...
        %    max(PowerPred_Int_machine3) + max(PowerPred_Int_machine4) + ...
        %    max(PowerPred_Int_machine5) - PMax;

%          Gaussian Process Optimization in the Bandit Setting paper's bounds           
%          beta_machine1 = sqrt(2 * log(abs(x(1))*iterations^2*pi^2/(6*0.05)));
%          beta_machine2 = sqrt(2 * log(abs(x(2))*iterations^2*pi^2/(6*0.05)));

        % TODO: Why are the maxes required here?  Isn't pred_ints always a vector?
        c(1) = max(pred_ints(1)) + max(pred_ints(2)) + ...
            max(pred_ints(3)) + max(pred_ints(4)) + ...
            max(pred_ints(5)) - PMax;

        ceq = [];

