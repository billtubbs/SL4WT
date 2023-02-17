function [sys,x0,str,tss] = load_opt(t,x,u,flag,Param,X_ss)

switch flag

    case 0	% Initialize the states and sizes
       [sys,x0,str,tss] = mdlInitialSizes(t,x,u,X_ss);
         
    case 3   % Calculate the outputs

       sys = mdlOutputs(t,x,u,Param);

%    case 2	% Update

%    case 1	% Obtain derivatives of states

%       sys = mdlDerivatives(t,x,u,Param);

    otherwise
       sys = [];

end

% ******************************************
% Sub-routines or Functions
% ******************************************

% ******************************************
% Initialization
% ******************************************

function [sys,x0,str,tss] = mdlInitialSizes(t,x,u,X_ss)
global LOData LOModelData curr_iteration ...
    gprMdlLP_machine1 gprMdlLP_machine2 gprMdlLP_machine3 ...
    gprMdlLP_machine4 gprMdlLP_machine5 total_uncertainty explore ...
    explore_signal

% This handles initialization of the function.
% Call simsize of a sizes structure.
sizes = simsizes;
sizes.NumContStates  = 0;     % continuous states
sizes.NumDiscStates  = 0;     % discrete states
sizes.NumOutputs     = 5;     % outputs of model 
sizes.NumInputs      = 11;     % inputs of model
sizes.DirFeedthrough = 1;     % System is causal
sizes.NumSampleTimes = 1;     %
sys = simsizes(sizes);        %
x0  = X_ss;                   % Initialize the states 

str = [];	                  % set str to an empty matrix.
tss = [250,0];	              % sample time: [period, offset].
curr_iteration = 0;
total_uncertainty = [];
explore = 0;
explore_signal = [];

% Initialize GP models using pre-defined model data points
gprMdlLP_machine1 = fitrgp(LOModelData.LoadMachine1, ...
    LOModelData.PowerMachine1, 'KernelFunction', 'squaredexponential');
gprMdlLP_machine2 = fitrgp(LOModelData.LoadMachine2, ...
    LOModelData.PowerMachine2, 'KernelFunction', 'squaredexponential');
gprMdlLP_machine3 = fitrgp(LOModelData.LoadMachine2, ...
    LOModelData.PowerMachine2, 'KernelFunction', 'squaredexponential');
gprMdlLP_machine4 = fitrgp(LOModelData.LoadMachine2, ...
    LOModelData.PowerMachine2, 'KernelFunction', 'squaredexponential');
gprMdlLP_machine5 = fitrgp(LOModelData.LoadMachine2, ...
    LOModelData.PowerMachine2, 'KernelFunction', 'squaredexponential');

% Initialize empty dataset
LOData.Load_Target = [];
LOData.LoadMachine1 = [];
LOData.PowerMachine1 = [];
LOData.LoadMachine2 = [];
LOData.PowerMachine2 = [];
LOData.LoadMachine3 = [];
LOData.PowerMachine3 = [];
LOData.LoadMachine4 = [];
LOData.PowerMachine4 = [];
LOData.LoadMachine5 = [];
LOData.PowerMachine5 = [];


% ******************************************
%  Outputs
% ******************************************

function [sys] = mdlOutputs(t,x,u,Param)
global LOData LOModelData curr_iteration ...
    gprMdlLP_machine1 gprMdlLP_machine2 gprMdlLP_machine3 ...
    gprMdlLP_machine4 gprMdlLP_machine5 Current_Load_Target ...
    PMax SteadyState explore explore_signal ...
    significance total_uncertainty

% Inputs
% Update data history with new measurements
LOData.Load_Target = [LOData.Load_Target; u(1)];
LOData.LoadMachine1 = [LOData.LoadMachine1; u(2)];
LOData.LoadMachine2 = [LOData.LoadMachine2; u(3)];
LOData.LoadMachine3 = [LOData.LoadMachine3; u(4)];
LOData.LoadMachine4 = [LOData.LoadMachine4; u(5)];
LOData.LoadMachine5 = [LOData.LoadMachine5; u(6)];
LOData.PowerMachine1 = [LOData.PowerMachine1; u(7)];
LOData.PowerMachine2 = [LOData.PowerMachine2; u(8)];
LOData.PowerMachine3 = [LOData.PowerMachine3; u(9)];
LOData.PowerMachine4 = [LOData.PowerMachine4; u(10)];
LOData.PowerMachine5 = [LOData.PowerMachine5; u(11)];

% Steady State Detection for each machine
mean_abs_Load_diff_machine = nan(1, 5);
mean_abs_Power_diff_machine = nan(1, 5);

% Machine 1
if size(LOData.LoadMachine1, 1) > 3
    mean_abs_Load_diff_machine(1) = ...
        mean(abs(diff(LOData.LoadMachine1(end-3:end))));
    mean_abs_Power_diff_machine(1) = ...
        mean(abs(diff(LOData.PowerMachine1(end-3:end))));
end

% Machine 2
if size(LOData.LoadMachine2, 1) > 3
    mean_abs_Load_diff_machine(2) = ...
        mean(abs(diff(LOData.LoadMachine2(end-3:end))));
    mean_abs_Power_diff_machine(2) = ...
        mean(abs(diff(LOData.PowerMachine2(end-3:end))));
end

% Machine 3
if size(LOData.LoadMachine3, 1) > 3
    mean_abs_Load_diff_machine(3) = ...
        mean(abs(diff(LOData.LoadMachine3(end-3:end))));
    mean_abs_Power_diff_machine(3) = ...
        mean(abs(diff(LOData.PowerMachine3(end-3:end))));
end

% Machine 4
if size(LOData.LoadMachine4, 1) > 3
    mean_abs_Load_diff_machine(4) = ...
        mean(abs(diff(LOData.LoadMachine4(end-3:end))));
    mean_abs_Power_diff_machine(4) = ...
        mean(abs(diff(LOData.PowerMachine4(end-3:end))));
end

% Machine 5
if size(LOData.LoadMachine5, 1) > 3
    mean_abs_Load_diff_machine(5) = ...
        mean(abs(diff(LOData.LoadMachine5(end-3:end))));
    mean_abs_Power_diff_machine(5) = ...
        mean(abs(diff(LOData.PowerMachine5(end-3:end))));
end

if (all(mean_abs_Load_diff_machine <= 2) ...
        && all(mean_abs_Power_diff_machine <= 5))
    SteadyState = 1;
else
    SteadyState = 0;
end


% Gaussian process model Updates (if conditions met)

if SteadyState == 1
    % for machine 1
     if min(abs(LOModelData.LoadMachine1 - LOData.LoadMachine1(end,1))) >= 4
        
        LOModelData.LoadMachine1 = ...
            [LOModelData.LoadMachine1; LOData.LoadMachine1(end,1)];
        LOModelData.PowerMachine1 = ...
            [LOModelData.PowerMachine1; LOData.PowerMachine1(end,1)];

        % Model Update
        gprMdlLP_machine1 = fitrgp(LOModelData.LoadMachine1, ...
            LOModelData.PowerMachine1, 'KernelFunction','squaredexponential');
%         gprMdlLP_machine1 = fitrgp(LOModelData.LoadMachine1, ...
%             LOModelData.PowerMachine1, 'KernelFunction', 'squaredexponential', ...
%             'KernelParameters', [15.0; 95.7708]);

     end

    % for machine 2
     if min(abs(LOModelData.LoadMachine2 - LOData.LoadMachine2(end,1))) >= 4
        
        LOModelData.LoadMachine2 = ...
            [LOModelData.LoadMachine2;LOData.LoadMachine2(end,1)];
        LOModelData.PowerMachine2 = ...
            [LOModelData.PowerMachine2;LOData.PowerMachine2(end,1)];
        
        % Model Update
        gprMdlLP_machine2 = fitrgp(LOModelData.LoadMachine2, ...
            LOModelData.PowerMachine2, 'KernelFunction','squaredexponential');
%         gprMdlLP_machine2 = fitrgp(LOModelData.LoadMachine2, ...
%             LOModelData.PowerMachine2, 'KernelFunction', 'squaredexponential', ...
%             'KernelParameters', [15.0; 111.0653]);

     end

     % for machine 3
     if min(abs(LOModelData.LoadMachine3 - LOData.LoadMachine3(end,1))) >= 4
        
        LOModelData.LoadMachine3 = ...
            [LOModelData.LoadMachine3;LOData.LoadMachine3(end,1)];
        LOModelData.PowerMachine3 = ...
            [LOModelData.PowerMachine3;LOData.PowerMachine3(end,1)];
        
        % Model Update
        gprMdlLP_machine3 = fitrgp(LOModelData.LoadMachine3, ...
            LOModelData.PowerMachine3, 'KernelFunction','squaredexponential');
%         gprMdlLP_machine3 = fitrgp(LOModelData.LoadMachine3, ...
%             LOModelData.PowerMachine3, 'KernelFunction', 'squaredexponential', ...
%             'KernelParameters', [15.5848; 153.5634]);

     end

      % for machine 4
     if min(abs(LOModelData.LoadMachine4 - LOData.LoadMachine4(end,1))) >= 4

        LOModelData.LoadMachine4 = ...
            [LOModelData.LoadMachine4;LOData.LoadMachine4(end,1)];
        LOModelData.PowerMachine4 = ...
            [LOModelData.PowerMachine4;LOData.PowerMachine4(end,1)];

        % Model Update
        gprMdlLP_machine4 = fitrgp(LOModelData.LoadMachine4, ...
            LOModelData.PowerMachine4, 'KernelFunction','squaredexponential');
%         gprMdlLP_machine4 = fitrgp(LOModelData.LoadMachine4, ...
%             LOModelData.PowerMachine4, 'KernelFunction', 'squaredexponential', ...
%             'KernelParameters', [15;280.8635]);

     end

      % for machine 5
     if min(abs(LOModelData.LoadMachine5 - LOData.LoadMachine5(end,1))) >= 4
        
        LOModelData.LoadMachine5 = ...
            [LOModelData.LoadMachine5;LOData.LoadMachine5(end,1)];
        LOModelData.PowerMachine5 = ...
            [LOModelData.PowerMachine5;LOData.PowerMachine5(end,1)];
        
        % Model Update
        gprMdlLP_machine5 = fitrgp(LOModelData.LoadMachine5, ...
            LOModelData.PowerMachine5, 'KernelFunction','squaredexponential');
       % gprMdlLP_machine5 = fitrgp(LOModelData.LoadMachine5, ...
       %      LOModelData.PowerMachine5, 'KernelFunction', 'squaredexponential', ...
       %      'KernelParameters', [15.1001;236.1767]);

    end

    % Make predictions - optional, for plotting only
    % Set prediction points over operating range of each machine.
    % Note: Machines 4 and 5 use same values as machine 3
    operating_interval_machine1 = (56:220)';
    operating_interval_machine2 = (237:537)';
    operating_interval_machine3 = (194:795)';
    
    % Gaussian process model predictions
    [mean_machine1, sigma_machine1, interval_machine1] = predict( ...
        gprMdlLP_machine1, operating_interval_machine1, 'Alpha', significance); 
    [mean_machine2, sigma_machine2, interval_machine2] = predict( ...
        gprMdlLP_machine2, operating_interval_machine2, 'Alpha', significance);
    [mean_machine3, sigma_machine3, interval_machine3] = predict( ...
        gprMdlLP_machine3, operating_interval_machine3, 'Alpha', significance); 
    [mean_machine4, sigma_machine4, interval_machine4] = predict( ...
        gprMdlLP_machine4, operating_interval_machine3, 'Alpha', significance);
    [mean_machine5, sigma_machine5, interval_machine5] = predict( ...
        gprMdlLP_machine5, operating_interval_machine3, 'Alpha', significance); 
    
    % Sum covariance matrices to use as indicator of uncertainty
    sum1 = sum(sigma_machine1);
    sum2 = sum(sigma_machine2);
    sum3 = sum(sigma_machine3);
    sum4 = sum(sigma_machine4);
    sum5 = sum(sigma_machine5);
    
    total_uncertainty = [total_uncertainty; sum1+sum2+sum3+sum4+sum5];
    explore = [explore; explore_signal];
    disp(explore_signal)
    
    % Plot GP model predictions
    figure(1); clf
    c = get(gca, 'colororder');
    % Plot predictions over full interval
    plot(operating_interval_machine1, mean_machine1, 'color', c(1, :)); hold on
    plot(operating_interval_machine2, mean_machine2, 'color', c(2, :))
    plot(operating_interval_machine3, mean_machine3, 'color', c(3, :))
    plot(operating_interval_machine3, mean_machine4, 'color', c(4, :))
    plot(operating_interval_machine3, mean_machine5, 'color', c(5, :))
    % Plot previous data points to which model has been fitted
    plot(LOModelData.LoadMachine1, LOModelData.PowerMachine1, '.', 'color', c(1, :))
    plot(LOModelData.LoadMachine2, LOModelData.PowerMachine2, '.', 'color', c(2, :))
    plot(LOModelData.LoadMachine3, LOModelData.PowerMachine3, '.', 'color', c(3, :))
    plot(LOModelData.LoadMachine4, LOModelData.PowerMachine4, '.', 'color', c(4, :))
    plot(LOModelData.LoadMachine5, LOModelData.PowerMachine5, '.', 'color', c(5, :))
    grid on
    legend(compose("machine %d", 1:5), 'location', 'best')
    xlabel("Load")
    ylabel("Power consumption")
    title(compose("$t = %d$", t), 'Interpreter', 'latex')
    
    % Plot GP model uncertainties
    figure(2); clf
    c = get(gca, 'colororder');
    plot(operating_interval_machine1, sigma_machine1, 'color', c(1, :)); hold on
    plot(operating_interval_machine2, sigma_machine2, 'color', c(2, :))
    plot(operating_interval_machine3, sigma_machine3, 'color', c(3, :))
    plot(operating_interval_machine3, sigma_machine4, 'color', c(4, :))
    plot(operating_interval_machine3, sigma_machine5, 'color', c(5, :))
    grid on
    legend(compose("machine %d", 1:5), 'location', 'best')
    xlabel("Load")
    ylabel("sigma")
    title(compose("$t = %d$", t), 'Interpreter', 'latex')

    % Put a breakpoint or pause here if you want to pause to view plots
    %pause

end


% Load optimization
Current_Load_Target = LOData.Load_Target(end,1);

% TODO: What is this?
PMax = 1580;

% options = optimoptions('fmincon', ...
%   'MaxIterations', 500000, 
%   'ConstraintTolerance', 1e-14,
%   "EnableFeasibilityMode", true,
%   "SubproblemAlgorithm", "cg",
%   "StepTolerance", 1e-10, 
%   "MaxFunctionEvaluations", 5000);
%  , "StepTolerance",1e-14, "OptimalityTolerance",1e-14);
options = optimoptions("fmincon", "SubproblemAlgorithm", "cg", ...
    "MaxIterations", 500000, "Display", "iter");
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

gen_load_target = fmincon( ...
    @LoadObjFun, ...
    [56.1, 237.1, 194.1, 194.1, 194.1], ...
    [],[],[],[], ...
    [56,237,194,194,194], ...
    [220,537,795,795,795], ...
    @MaxPowerConstraint, ...
    options);

% Send outputs
sys(1) = gen_load_target(1); 
sys(2) = gen_load_target(2);      
sys(3) = gen_load_target(3);
sys(4) = gen_load_target(4);
sys(5) = gen_load_target(5);
% end





