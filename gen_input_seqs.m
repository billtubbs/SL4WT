% Generate load target input sequences for simulations and associated
% 'seed' data for model training.

clear all

addpath("yaml")

rng(0)

% Directory where simulation config file is and input data
% will be stored
data_dir = "data";

% Load simulation config file with machine parameters
filename = "sim_config.yaml";
sim_config = yaml.loadFile(fullfile(data_dir, filename), ...
    "ConvertToArray", true);

machine_names = fieldnames(sim_config.machines);
n_machines = numel(machine_names);

% Constraints: lower and upper bounds of load for each machine
op_limits = cell2mat( ...
    cellfun(@(name) sim_config.machines.(name).params.op_limits, ...
        machine_names, 'UniformOutput', false) ...
);

% Full operating range
full_op_limit = sum(op_limits);
fprintf("Full operating range: %g to %g kW\n", full_op_limit)
assert(isequal(full_op_limit, [875 3142]))

% Simulation scenarios:
%
% 1-5. 5 different constant load targets between 1000 and 2600 kW 
%    with training points around same levels.
% 6-10. Initial load and training points between 900 and 1100 kW with 1 step 
%    change to 2500 kW at t = 2000 s
% 11-20. Initial load and training points around 830 kW with 6 
%    pseudo-random step-changes (one every 1000 seconds) according 
%    to a bounded random walk between 830 and 2500 kW.
%

% Time sequence
t = (0:1000:7000)';

% Number scenarios
scenario = 1;

%% Scenarios 1 to 5 - constant load targets

% Define range of operating targets
load_targets = 1000:500:3000;
assert(all(load_targets < full_op_limit(2)))
assert(all(load_targets > full_op_limit(1)))

for i = 1:numel(load_targets)
    load_target = load_targets(i) .* ones(size(t));

    % Store input signals as struct containing time series
    inputs = struct();

    ts = timeseries(load_target, t);
    name = "load_target";
    ts.name = name;
    ts.TimeInfo.Units = 'seconds';
    ts.DataInfo.Interpolation.Name = 'zoh';
    ts.DataInfo.Units = 'kW';

    inputs.(name) = ts;

    % Store time series in a Simulink dataset
    % TODO: Couldn't get this working. Was planning to use
    %  signal editor block but failed.
    %dsName = compose("LoadTargetSequence%d", scenario);
    %ds = Simulink.SimulationData.Dataset();
    %ds.Name = dsName;
    %ds = addElement(ds, ts);

    % Save simulation data file
    filename = compose("load_sequence_%d.mat", scenario);
    save(fullfile(data_dir, filename), "inputs")
    fprintf("Input data file '%s' saved\n", filename)

    scenario = scenario + 1;
end

%% Scenarios 6 to 10 - one step change
for i = 1:numel(load_targets)

    % Make a sequence with one random step change, making
    % sure the step amplitude is not zero
    l1 = randi(length(load_targets));
    load_target = load_targets(l1) .* ones(size(t));
    l2 = randsample([1:l1-1 l1+1:length(load_targets)], 1);
    t_step = t(2);
    load_target(t >= t_step) = load_targets(l2);

    % Store input signals as struct containing time series
    inputs = struct();

    ts = timeseries(load_target .* ones(size(t)), t);
    name = "load_target";
    ts.name = name;
    ts.TimeInfo.Units = 'seconds';
    ts.DataInfo.Interpolation.Name = 'zoh';
    ts.DataInfo.Units = 'kW';

    inputs.(name) = ts;

    % Save simulation data file
    filename = compose("load_sequence_%d.mat", scenario);
    save(fullfile(data_dir, filename), "inputs")
    fprintf("Input data file '%s' saved\n", filename)

    scenario = scenario + 1;
end


%% Scenarios 11 to 20 - bounded random walk

figure(1); clf

% Bounded random walk parameters
beta = -15;  % note beta is k from Nicolau paper
alpha1 = 3;
alpha2 = 3;
tau = 100;
x = linspace(95, 105, 201);
a = brw_reversion_bias(x, alpha1, alpha2, beta, tau);
plot(x, a)
grid on

% Noise std. dev.
sd_e = 1;

for i = 1:10

    % Mid-point of load range
    load_mid = mean(load_targets([1 end]));
    % Initial load
    load0 = load_targets(1) + rand() .* diff(load_targets([1 end]));

    % Generate a bounded random walk (BRW) sequence
    xkm1 = tau + 5 .* (load0 - load_mid) ./ (load_targets(end) - load_mid);
    n_steps = (length(t) - 2) * 10 + 1;
    phi = 0.5;
    brw = sample_bounded_random_walk(sd_e, beta, alpha1, alpha2, ...
        n_steps, tau, phi, xkm1);

    load_target = load0 .* ones(size(t));
    load_target(2:end) = (brw(1:10:end) - tau) ./ 5 .* (load_targets(end) - load_mid) + load_mid;
    figure(2); clf
    plot(990 + (1:n_steps)' .* 100, (brw - tau) ./ 5 .* (load_targets(end) - load_mid) + load_mid, '.-'); hold on
    stairs(t, load_target, 'LineWidth', 2);
    yline(full_op_limit)
    ylim([700 3400])
    grid on

    % Store input signals as struct containing time series
    inputs = struct();

    ts = timeseries(load_target .* ones(size(t)), t);
    name = "load_target";
    ts.name = name;
    ts.TimeInfo.Units = 'seconds';
    ts.DataInfo.Interpolation.Name = 'zoh';
    ts.DataInfo.Units = 'kW';

    inputs.(name) = ts;

    % Save simulation data file
    filename = compose("load_sequence_%d.mat", scenario);
    save(fullfile(data_dir, filename), "inputs")
    fprintf("Input data file '%s' saved\n", filename)

    scenario = scenario + 1;
end

grid on