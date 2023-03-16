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

% Load initial training data from file
training_data = struct();
for machine = string(fieldnames(config.machines))'
    filename = config.machines.(machine).trainingData;
    filepath = fullfile("simulations", config.simulation.name, "data", filename);
    training_data.(machine) = readtable(filepath);
end

% Create model objects by running the setup scripts with 
% the pre-defined model data specified in the config struct 
for machine = string(fieldnames(config.machines))'
    model_name = config.machines.(machine).model;
    model_config = config.models.(model_name);

    % Run model setup script
    [models.(machine), model_vars.(machine)] = feval( ...
        model_config.setupFcn, ...
        training_data.(machine), ...
        model_config.params ...
    );

    % Store pre-training data points in global simulation data arrays
    n_pre_train = size(training_data.(machine), 1);
    LOModelData.Machines.(machine).Iteration = nan(n_pre_train, 1);
    LOModelData.Machines.(machine).Time = nan(n_pre_train, 1);
    % TODO: Consider just saving all training data in one array/table
    LOModelData.Machines.(machine).X = training_data.(machine){:, ...
        model_config.params.predictorNames ...
    };
    LOModelData.Machines.(machine).Y = training_data.(machine){:, ...
        model_config.params.responseNames ...
    };

end

% Arrays to store simulation data
LOData.Iteration = [];
LOData.Time = [];
LOData.LoadTarget = [];
LOData.SteadyState = [];
LOData.ModelUpdates = [];
LOData.TotalUncertainty = [];
for machine = string(fieldnames(config.machines))'
    LOData.Machines.(machine).X = [];
    LOData.Machines.(machine).Y = [];
end


% ******************************************
%  Outputs
% ******************************************

function [sys] = mdlOutputs(t,ci,u,config)
global LOData LOModelData curr_iteration models model_vars ...
    CurrentLoadTarget

% Directory where simulation results will be stored
sim_name = config.simulation.name;

% Process inputs from Simulink
% Update data history with new data and measurements
CurrentLoadTarget = u(1);
LOData.LoadTarget = [LOData.LoadTarget; CurrentLoadTarget];
LOData.Iteration = [LOData.Iteration; curr_iteration];
LOData.Time = [LOData.Time; t];
machine_names = string(fieldnames(config.machines))';
n_machines = numel(machine_names);
for i = 1:n_machines
    machine = machine_names{i};
    LOData.Machines.(machine).X = ...
        [LOData.Machines.(machine).X; u(i+1)];
    LOData.Machines.(machine).Y = ...
        [LOData.Machines.(machine).Y; u(i+1+n_machines)];
end

% Steady state detection for each machine
SteadyState = nan(n_machines, 1);
for i = 1:n_machines
    machine = machine_names{i};
    machine_config = config.machines.(machine);

    % Check all n_ss previous samples including the current
    % one are similar to within the same tolerance
    n_ss = config.machines.(machine).params.n_ss;
    if size(LOData.Machines.(machine).X, 1) >= n_ss

        % Set steady state flag if load and power readings of all
        % machines have not significantly changed in most recent
        % n_ss samples.
        max_X_difference = ...
            max(LOData.Machines.(machine).X(end-n_ss+1:end)) ...
            - min(LOData.Machines.(machine).X(end-n_ss+1:end));
        max_Y_difference = ...
            max(LOData.Machines.(machine).Y(end-n_ss+1:end)) ...
            - min(LOData.Machines.(machine).Y(end-n_ss+1:end));

        if (all(max_X_difference <= machine_config.params.x_tol) ...
                && all(max_Y_difference <= machine_config.params.y_tol))
            SteadyState(i) = 1;
        else
            SteadyState(i) = 0;
        end
    else
        SteadyState(i) = 0;
    end
end
LOData.SteadyState = [LOData.SteadyState; SteadyState'];

% Do model updates if steady-state conditions met
ModelUpdates = zeros(1, n_machines);
if all(SteadyState == 1)

    for i = 1:n_machines
        machine = machine_names{i};
        machine_config = config.machines.(machine);
        model_name = machine_config.model;
        model_config = config.models.(model_name);

%         % Check if current load is close to previous training points
%         %TODO: The following is not setup for MIMO yet
%         if min(abs(LOData.Machines.(machine).X(end, :) ...
%                 - LOModelData.Machines.(machine).X)) ...
%                     >= machine_config.params.x_tol ...
%             && min(abs(LOData.Machines.(machine).Y(end, :) ...
%                 - LOModelData.Machines.(machine).Y)) ...
%                     >= machine_config.params.y_tol
% 

            % Add current data to training history
            LOModelData.Machines.(machine).X = ...
                [LOModelData.Machines.(machine).X; 
                 LOData.Machines.(machine).X(end,:)];
            LOModelData.Machines.(machine).Y = ...
                [LOModelData.Machines.(machine).Y; 
                 LOData.Machines.(machine).Y(end,:)];
            LOModelData.Machines.(machine).Iteration = ...
                [LOModelData.Machines.(machine).Iteration; curr_iteration];
            LOModelData.Machines.(machine).Time = [ ...
                LOModelData.Machines.(machine).Time; t];

        % Update model
        var_names = [
            string(model_config.params.predictorNames) ...
            string(model_config.params.responseNames)
        ];
        training_data = array2table( ...
            [LOModelData.Machines.(machine).X ...
             LOModelData.Machines.(machine).Y], ...
            "VariableNames", var_names ...
        );
        [models.(machine), model_vars.(machine)] = builtin( ...
            "feval", ...
            model_config.updateFcn, ...
            models.(machine), ...
            training_data, ...
            model_vars.(machine), ...
            model_config.params ...
        );

        ModelUpdates(i) = 1;

        %end
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
    op_limits = machine_config.params.op_limits;

    % Set prediction points over operating range of each machine.
    op_interval = (op_limits(1):op_limits(2))';
    model_name = config.machines.(machine).model;
    model_config = config.models.(model_name);

    % Predict model outputs
    [y_mean, y_sigma, y_int] = builtin( ...
        "feval", ...
        model_config.predictFcn, ...
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
    cellfun(@(name) config.machines.(name).params.op_limits, ...
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

% Objective function to be miminized
obj_func_name = config.optimizer.obj_func;
obj_func = @(x) feval(obj_func_name, x, config);

% Constraint function (nonlinear)
const_func_name = config.optimizer.const_func;
const_func = @(x) feval(const_func_name, x, config);

x0 = config.optimizer.X0';

% Test functions before starting optimizer (for debugging only)
% J = obj_func(x0);
% c = const_func(x0);

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
assert(isequal(size(gen_load_target), [n_machines 1]))
sys = gen_load_target;
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
        "load_opt_out.mat");
    save(filespec, 'curr_iteration', 'LOData', 'LOModelData', ...
        'model_vars', 'models')

% end


