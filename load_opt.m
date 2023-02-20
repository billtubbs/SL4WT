function [sys,x0,str,tss] = load_opt(t,x,u,flag,config)

addpath("plot-utils")

switch flag

    case 0	% Initialize the states and sizes
       [sys,x0,str,tss] = mdlInitialSizes(t,x,u,config);

    case 1	% Obtain derivatives of states
       sys = mdlDerivatives(t,x,u,Param);  % this is not implemented

%    case 2	% Update

    case 3   % Calculate the outputs
       sys = mdlOutputs(t,x,u,config);

    otherwise
       sys = [];

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

    % Initialize empty arrays to store simulation results
    LOModelData.(machine).Load = training_data.Load;
    LOModelData.(machine).Power = training_data.Power;
    LOData.(machine).Load = [];
    LOData.(machine).Power = [];

end

% Arrays to store simulation data
LOData.Iteration = [];
LOData.Time = [];
LOData.Load_Target = [];
LOData.TotalUncertainty = [];
LOData.SteadyState = [];


% ******************************************
%  Outputs
% ******************************************

function [sys] = mdlOutputs(t,ci,u,config)
global LOData LOModelData curr_iteration models model_vars ...
    Current_Load_Target

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
LOData.SteadyState = [LOData.SteadyState SteadyState];

% Do model updates if conditions met
if SteadyState == 1

    for machine = config.machines.names
        % Check if current load is close to previous training points
        if min(abs(LOData.(machine).Load(end,1)) ...
                - LOModelData.(machine).Load) >= 4

            % Add current data to training history
            LOModelData.(machine).Load = ...
                [LOModelData.(machine).Load; LOData.(machine).Load(end,:)];
            LOModelData.(machine).Power = ...
                [LOModelData.(machine).Power; LOData.(machine).Power(end,:)];

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

        end
    end

    figure(1); clf
    y_labels = "Power";
    line_label = "predicted";
    area_label = "confidence interval";
    x_label = "Load";

    % Model predictions - this is only needed for calculation of 
    % total uncertainty or if plots are needed.
    y_means = cell(1, n_machines);
    y_sigmas = cell(1, n_machines);
    ci = cell(1, n_machines);
    for i = 1:n_machines
        machine = config.machines.names{i};
        machine_config = config.machines.(machine);
        % Set prediction points over operating range of each machine.
        op_interval = ( ...
            machine_config.op_limits(1):machine_config.op_limits(2) ...
        )';
        model_name = config.machines.(machine).model;
        model_config = config.models.(model_name);
        [y_means{i}, y_sigmas{i}, ci{i}] = feval( ...
            model_config.predict_script, ...
            models.(machine), ...
            op_interval, ...
            model_vars.(machine), ...
            model_config.params ...
        );

        % Plot predictions and training data points
        subplot(1, n_machines, i);
        make_statplot(y_means{i}, ci{i}(:, 1), ci{i}(:, 2), ...
            op_interval, y_labels, line_label, area_label, x_label)
        h = findobj(gcf, 'Type', 'Legend');
        leg_labels = h.String;
        % Add training data points to plot
        plot(LOModelData.(machine).Load, LOModelData.(machine).Power, ...
            'k.', 'MarkerSize', 10)
        legend([leg_labels 'data'], 'Location', 'southeast')
        text(0.05, 0.95, compose("$t=%d$", t), 'Units', 'normalized', ...
            'Interpreter', 'latex')
        title(compose("Machine %d", i), 'Interpreter', 'latex')

    end

    grid on
    % Size figure appropriately
    s = get(gcf, 'Position');
    set(gcf, 'Position', [s(1:2) 420+280*n_machines 280]);
    sim_name = config.simulation.name;
    filename = compose("model_preds_%.0f.pdf", t);
    exportgraphics(gcf, fullfile("simulations", sim_name, "plots", filename))
    disp('Stop')

    % Sum covariance matrices as an indicator of model uncertainty
    total_uncertainty = sum(cellfun(@sum, y_sigmas));
    LOData.TotalUncertainty = [LOData.TotalUncertainty; total_uncertainty];

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

    curr_iteration = curr_iteration + 1;

end


% Load optimization
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

% Send outputs
sys(1) = gen_load_target(1); 
sys(2) = gen_load_target(2);      
sys(3) = gen_load_target(3);
sys(4) = gen_load_target(4);
sys(5) = gen_load_target(5);
% end





