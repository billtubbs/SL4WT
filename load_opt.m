function [sys,x0,str,tss] = load_opt(t,x,u,flag,config)

addpath("plot-utils")

switch flag

    case 0	% Initialize the states and sizes
        [sys,x0,str,tss] = mdlInitialSizes(t,x,u,config);

    case 2	% Update
        sys = [];

    case 3   % Calculate the outputs
        sys = mdlOutputs(t,x,u,config);

    case 9   % Finish and save results
        mdlTerminate(t,x,u,config);

    otherwise
        DAStudio.error('Simulink:blocks:unhandledFlag', num2str(flag));

end

% ******************************************
% Sub-routines or Functions
% ******************************************

% ******************************************
% Initialization
% ******************************************

function [sys,x0,str,tss] = mdlInitialSizes(t,x,u,config)
global LOData LOModelData curr_iteration models model_vars

% This handles initialization of the function.
% Call simsize of a sizes structure.
sizes = simsizes;
sizes.NumContStates  = config.block.NumContStates;      % continuous states
sizes.NumDiscStates  = config.block.NumDiscStates;      % discrete states
sizes.NumOutputs     = config.block.NumOutputs;         % outputs of model 
sizes.NumInputs      = config.block.NumInputs;          % inputs of model
sizes.DirFeedthrough = config.block.DirFeedthrough;     % System is causal
sizes.NumSampleTimes = config.block.NumSampleTimes;     %
sys = simsizes(sizes);
x0  = config.block.x0;              % Initial states 

str = [];	                  % set str to an empty matrix.
tss = config.block.tss;	  % sample time: [period, offset].

% Initialize global variables (these are used to avoid saving
% all the state information as Simulink state variables)
curr_iteration = 0;

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct 
for machine = config.machines.names
    model_name = config.machines.(machine).model;
    training_data = config.training.data.(machine);
    training_data.Load = training_data.Load';
    training_data.Power = training_data.Power';
    model_config = config.models.(model_name);

    % Run model setup script
    [models.(machine), model_vars.(machine)] = feval( ...
        model_config.setup_script, ...
        training_data, ...
        model_config.params ...
    );

    % Save pre-training data points
    n_pre_train = size(training_data.Load, 1);
    assert(size(training_data.Power, 1) == n_pre_train)
    LOModelData.(machine).Iteration = nan(n_pre_train, 1);
    LOModelData.(machine).Time = nan(n_pre_train, 1);
    LOModelData.(machine).Load = training_data.Load;
    LOModelData.(machine).Power = training_data.Power;

end

% Arrays to store simulation data
LOData.Iteration = [];
LOData.Time = [];
LOData.Load_Target = [];
LOData.SteadyState = [];
LOData.ModelUpdates = [];
LOData.TotalUncertainty = [];
for machine = config.machines.names
    LOData.(machine).Load = [];
    LOData.(machine).Power = [];
end


% ******************************************
%  Outputs
% ******************************************

function [sys] = mdlOutputs(t,ci,u,config)
global LOData LOModelData curr_iteration models model_vars ...
    Current_Load_Target

% Directory where simulation results will be stored
sim_name = config.simulation.name;

% Process inputs from Simulink
% Update data history with new data and measurements
Current_Load_Target = u(1);
LOData.Load_Target = [LOData.Load_Target; Current_Load_Target];
LOData.Iteration = [LOData.Iteration; curr_iteration];
LOData.Time = [LOData.Time; t];
n_machines = numel(config.machines.names);
for i = 1:n_machines
    machine = config.machines.names{i};
    LOData.(machine).Load = [LOData.(machine).Load; u(i+1)];
    LOData.(machine).Power = [LOData.(machine).Power; u(i+1+n_machines)];
end

% Steady State Detection for each machine
mean_abs_Load_diffs = nan(1, n_machines);
mean_abs_Power_diffs = nan(1, n_machines);
for i = 1:n_machines
    machine = config.machines.names{i};
    if size(LOData.(machine).Load, 1) > 3  % at least this many samples
        mean_abs_Load_diffs(i) = ...
            mean(abs(diff(LOData.(machine).Load(end-3:end))));
        mean_abs_Power_diffs(i) = ...
            mean(abs(diff(LOData.(machine).Power(end-3:end))));
    end
end

% Set steady state flag if load and power readings have 
% not significantly changed
if (all(mean_abs_Load_diffs <= 2) ...
        && all(mean_abs_Power_diffs <= 5))
    SteadyState = 1;
else
    SteadyState = 0;
end
LOData.SteadyState = [LOData.SteadyState; SteadyState];

% Do model updates if conditions met
ModelUpdates = zeros(1, n_machines);
if SteadyState == 1

    for i = 1:n_machines
        machine = config.machines.names{i};
        model = config.machines.(machine).model;

        % Check if current load is close to previous training points
        load_tol = config.models.model_1.params.x_tol;
        if min(abs(LOData.(machine).Load(end,1) ...
                - LOModelData.(machine).Load)) >= load_tol

            % Add current data to training history
            LOModelData.(machine).Load = ...
                [LOModelData.(machine).Load; LOData.(machine).Load(end,:)];
            LOModelData.(machine).Power = ...
                [LOModelData.(machine).Power; LOData.(machine).Power(end,:)];
            LOModelData.(machine).Iteration = ...
                [LOModelData.(machine).Iteration; curr_iteration];
            LOModelData.(machine).Time = [LOModelData.(machine).Time; t];

            % Update model
            training_data = struct();
            training_data.Load = LOModelData.(machine).Load;
            training_data.Power = LOModelData.(machine).Power;
            model_name = config.machines.(machine).model;
            model_config = config.models.(model_name);
            models.(machine) = feval(model_config.update_script, ...
                models.(machine), ...
                training_data, ...
                model_vars.(machine), ...
                model_config.params ...
            );

            ModelUpdates(i) = 1;

        end
    end

%     % Plot all GP model predictions on one plot
%     figure(1); clf
%     c = get(gca, 'colororder');
%     % Plot predictions over full interval
%     plot(operating_interval_machine1, mean_machine1, 'color', c(1, :)); hold on
%     plot(operating_interval_machine2, mean_machine2, 'color', c(2, :))
%     plot(operating_interval_machine3, mean_machine3, 'color', c(3, :))
%     plot(operating_interval_machine3, mean_machine4, 'color', c(4, :))
%     plot(operating_interval_machine3, mean_machine5, 'color', c(5, :))
%     % Plot previous data points to which model has been fitted
%     plot(LOModelData.LoadMachine1, LOModelData.PowerMachine1, '.', 'color', c(1, :))
%     plot(LOModelData.LoadMachine2, LOModelData.PowerMachine2, '.', 'color', c(2, :))
%     plot(LOModelData.LoadMachine3, LOModelData.PowerMachine3, '.', 'color', c(3, :))
%     plot(LOModelData.LoadMachine4, LOModelData.PowerMachine4, '.', 'color', c(4, :))
%     plot(LOModelData.LoadMachine5, LOModelData.PowerMachine5, '.', 'color', c(5, :))
%     grid on
%     legend(compose("machine %d", 1:5), 'location', 'best')
%     xlabel("Load")
%     ylabel("Power consumption")
%     title(compose("$t = %d$", t), 'Interpreter', 'latex')
%     
%     % Plot GP model uncertaintielss
%     figure(2); clf
%     c = get(gca, 'colororder');
%     plot(operating_interval_machine1, sigma_machine1, 'color', c(1, :)); hold on
%     plot(operating_interval_machine2, sigma_machine2, 'color', c(2, :))
%     plot(operating_interval_machine3, sigma_machine3, 'color', c(3, :))
%     plot(operating_interval_machine3, sigma_machine4, 'color', c(4, :))
%     plot(operating_interval_machine3, sigma_machine5, 'color', c(5, :))
%     grid on
%     legend(compose("machine %d", 1:5), 'location', 'best')
%     xlabel("Load")
%     ylabel("sigma")
%     title(compose("$t = %d$", t), 'Interpreter', 'latex')
% 
%     % Put a breakpoint or pause here if you want to pause to view plots
%     %pause

end

% Log whether models were updated this iteration
LOData.ModelUpdates = [LOData.ModelUpdates; ModelUpdates];

% Model predictions - this is needed for calculation of 
% total uncertainty and to save model predictions if the
% models were updated.
y_sigmas = cell(1, n_machines);
for i = 1:n_machines
    machine = config.machines.names{i};
    machine_config = config.machines.(machine);
    % Set prediction points over operating range of each machine.
    op_interval = ( ...
        machine_config.op_limits(1):machine_config.op_limits(2) ...
    )';
    model_name = config.machines.(machine).model;
    model_config = config.models.(model_name);
    [y_mean, y_sigma, y_int] = feval( ...
        model_config.predict_script, ...
        models.(machine), ...
        op_interval, ...
        model_vars.(machine), ...
        model_config.params ...
    );

    % Save for uncertainty calculation below
    y_sigmas{i} = y_sigma;

    if ModelUpdates(i) == 1
        % Save model prediction results to file
        model_preds = table(op_interval, y_mean, y_sigma, y_int);
        filename = compose("%s_%s_preds_%.0f.csv", sim_name, machine, t);
        writetable(model_preds, fullfile("simulations", sim_name, ...
            "results", filename))
    end

end

% Sum covariance matrices as an indicator of model uncertainty
total_uncertainty = sum(cellfun(@sum, y_sigmas));
LOData.TotalUncertainty = ...
    [LOData.TotalUncertainty; total_uncertainty];


% Do load optimization
% Lower and upper bounds of load for each machine
op_limits = cell2mat( ...
    cellfun(@(name) config.machines.(name).op_limits, ...
        config.machines.names, 'UniformOutput', false)' ...
);

% options = optimoptions('fmincon', ...
%   'MaxIterations', 500000, 
%   'ConstraintTolerance', 1e-14,
%   "EnableFeasibilityMode", true,
%   "SubproblemAlgorithm", "cg",
%   "StepTolerance", 1e-10, 
%   "MaxFunctionEvaluations", 5000);
%  , "StepTolerance",1e-14, "OptimalityTolerance",1e-14);
options = optimoptions("fmincon", ...
    "SubproblemAlgorithm", "cg", ...
    "MaxIterations", config.optimizer.optimoptions.MaxIterations, ...
    "Display", config.optimizer.optimoptions.Display ...
);
% gen_load_target = fmincon( ...
%     @LoadObjFun, ...
%     [LOData.LoadMachine1(end,1), ...
%      LOData.LoadMachine2(end,1), ...
%      LOData.LoadMachine3(end,1), ...
%      LOData.LoadMachine4(end,1), ...
%      LOData.LoadMachine5(end,1)], ...
%     [],[],[],[], ...
%     [56,237,194,194,194], ...
%     [220,537,795,795,795], ...
%     @MaxPowerConstraint, ...
%     options);

obj_func_name = config.optimizer.obj_func;
const_func_name = config.optimizer.const_func;

obj_func = @(x) feval(obj_func_name, x, config);
const_func = @(x) feval(const_func_name, x, config);

gen_load_target = fmincon( ...
    obj_func, ...
    config.optimizer.X0', ...
    [], [], [], [], ...
    op_limits(:, 1), ...
    op_limits(:, 2), ...
    const_func, ...
    options);

% Note this is the simulation iteration, not the same as
% the model update iterations.
curr_iteration = curr_iteration + 1;

% Send outputs
sys(1) = gen_load_target(1); 
sys(2) = gen_load_target(2);      
sys(3) = gen_load_target(3);
sys(4) = gen_load_target(4);
sys(5) = gen_load_target(5);
% end


% ******************************************
% Terminate
% ******************************************

function mdlTerminate(t,x,u,config)
% Save workspace variables before quitting. This is useful
% when running automated simulations where the analysis is
% done later.  In theory a simulation could also be restarted
% using this data.

    global curr_iteration LOData LOModelData model_vars models

    sim_name = config.simulation.name;

    % Save variables from global workspace
    filespec = fullfile("simulations", sim_name, "results", ...
        "load_opt.mat");
    save(filespec, 'curr_iteration', 'LOData', 'LOModelData', ...
        'model_vars', 'models')

% end


