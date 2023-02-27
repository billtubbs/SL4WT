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
curr_iteration = 1;

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct 
for machine = string(fieldnames(config.machines))'
    model_name = config.machines.(machine).model;
    training_data = config.training.data.(machine);
    %TODO: Better to get this data from CSV file not config
    %      as yaml doesn't support arrays.
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
    LOModelData.(machine).Time(end) = 0;  % set time = 0 for last point
    LOModelData.Machines.(machine).Load = training_data.Load;
    LOModelData.Machines.(machine).Power = training_data.Power;

end

% Arrays to store simulation data
LOData.Iteration = [];
LOData.Time = [];
LOData.Load_Target = [];
LOData.SteadyState = [];
LOData.ModelUpdates = [];
LOData.TotalUncertainty = [];
for machine = string(fieldnames(config.machines))'
    LOData.Machines.(machine).Load = [];
    LOData.Machines.(machine).Power = [];
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
machine_names = string(fieldnames(config.machines))';
n_machines = numel(machine_names);
for i = 1:n_machines
    machine = machine_names{i};
    LOData.Machines.(machine).Load = ...
        [LOData.Machines.(machine).Load; u(i+1)];
    LOData.Machines.(machine).Power = ...
        [LOData.Machines.(machine).Power; u(i+1+n_machines)];
end

% Steady state detection for each machine
mean_abs_Load_diffs = nan(1, n_machines);
mean_abs_Power_diffs = nan(1, n_machines);
for i = 1:n_machines
    machine = machine_names{i};
    if size(LOData.Machines.(machine).Load, 1) > 3  % > this many samples
        mean_abs_Load_diffs(i) = ...
            mean(abs(diff(LOData.Machines.(machine).Load(end-3:end))));
        mean_abs_Power_diffs(i) = ...
            mean(abs(diff(LOData.Machines.(machine).Power(end-3:end))));
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
        machine = machine_names{i};

        % Check if current load is close to previous training points
        model = config.machines.(machine).model;
        load_tol = config.models.(model).params.x_tol;
        if min(abs(LOData.Machines.(machine).Load(end,1) ...
                - LOModelData.Machines.(machine).Load)) >= load_tol

            % Add current data to training history
            LOModelData.Machines.(machine).Load = ...
                [LOModelData.Machines.(machine).Load; 
                 LOData.Machines.(machine).Load(end,:)];
            LOModelData.Machines.(machine).Power = ...
                [LOModelData.Machines.(machine).Power; 
                 LOData.Machines.(machine).Power(end,:)];
            LOModelData.(machine).Iteration = ...
                [LOModelData.(machine).Iteration; curr_iteration];
            LOModelData.(machine).Time = [LOModelData.(machine).Time; t];

            % Update model
            training_data = struct();
            training_data.Load = LOModelData.Machines.(machine).Load;
            training_data.Power = LOModelData.Machines.(machine).Power;
            model_name = config.machines.(machine).model;
            model_config = config.models.(model_name);
            [models.(machine), model_vars.(machine)] = builtin( ...
                "feval", ...
                model_config.update_script, ...
                models.(machine), ...
                training_data, ...
                model_vars.(machine), ...
                model_config.params ...
            );

            ModelUpdates(i) = 1;

        end
    end
end

% Log whether models were updated this iteration
LOData.ModelUpdates = [LOData.ModelUpdates; ModelUpdates];

% Model predictions - this is needed for calculation of 
% total uncertainty and to save model predictions if the
% models were updated.
y_sigmas = cell(1, n_machines);
for i = 1:n_machines
    machine = machine_names{i};
    machine_config = config.machines.(machine);

    % Set prediction points over operating range of each machine.
    op_interval = ( ...
        machine_config.op_limits(1):machine_config.op_limits(2) ...
    )';
    model_name = config.machines.(machine).model;
    model_config = config.models.(model_name);

    % Predict model outputs
    [y_mean, y_sigma, y_int] = builtin( ...
        "feval", ...
        model_config.predict_script, ...
        models.(machine), ...
        op_interval, ...
        model_vars.(machine), ...
        model_config.params ...
    );

    % Save these for uncertainty calculation below
    y_sigmas{i} = y_sigma;

    if t == 0 || ModelUpdates(i) == 1
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


% Lower and upper bounds of load for each machine
op_limits = cell2mat( ...
    cellfun(@(name) config.machines.(name).op_limits, ...
        machine_names, 'UniformOutput', false)' ...
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

% Partial functions to pass config parameters to
% optimization functions

% Function to miminize
obj_func_name = config.optimizer.obj_func;
obj_func = @(x) feval(obj_func_name, x, config);

% Test function
x0 = config.optimizer.X0';
y = obj_func(x0);

% Constraint function
const_func_name = config.optimizer.const_func;
const_func = @(x) feval(const_func_name, x, config);

c = const_func(x0);

% Run the optimizer
gen_load_target = fmincon( ...
    obj_func, ...
    config.optimizer.X0', ...
    [], [], [], [], ...
    op_limits(:, 1), ...
    op_limits(:, 2), ...
    const_func, ...
    options);

% Simulation iteration (not the model updates iteration)
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


