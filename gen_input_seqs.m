% Generate load target input sequences for simulations
% TODO: generate 'seed' data points for model training.
%

clear all

addpath("yaml")

rng(0)

% Directory where simulation config file is and input data
% will be stored
data_dir = "data";
plot_dir = "plots";
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

% Load simulation config file with machine parameters
filename = "sys_config.yaml";
sys_config = yaml.loadFile(fullfile(data_dir, filename), ...
    "ConvertToArray", true);

machine_names = fieldnames(sys_config.equipment);
n_machines = numel(machine_names);

% Constraints: lower and upper bounds of load for each machine
op_limits = cell2mat( ...
    cellfun(@(name) sys_config.equipment.(name).params.op_limits, ...
        machine_names, 'UniformOutput', false) ...
);

% Full operating range
full_op_limit = sum(op_limits);
fprintf("Full operating range: %g to %g kW\n", full_op_limit)
assert(isequal(full_op_limit, [875 3142]))

% Simulation scenarios:
%
% 1-11. Small variations around constant load targets between 1000 
%    and 2600 kW.
% 12-22. Pseudo-random step-changes every 250 seconds according to 
%    a bounded random walk between 875 and 2500 kW.
%

% Time sequence
t = (0:1000:8000)';

% Count scenarios
scenario = 1;

% Step length (seconds)
dt_step = 250;

% Duration
t_stop = 16*dt_step;

% Lower and upper values
target_load_range = [1000 3000];


%% Scenarios 1 to 11 - constant load targets

% Define load target levels
load_targets = linspace(target_load_range(1), target_load_range(2), 11);

% Magnitude of BRW (kW)
mag_brw = 25;

% Step-size for BRW
dt_brw = 10;

% Std. dev. of BRW noise input
sd = 0.1;

nT = floor(t_stop / dt_brw);
n_seqs = length(load_targets);
assert(all(load_targets < full_op_limit(2)))
assert(all(load_targets > full_op_limit(1)))

% Sample times of BRw
t = dt_brw.*(0:nT)';

% Sample times of steps
t_step = t(1:dt_step/dt_brw:end);

load_seqs = nan(size(t_step, 1), n_seqs);

for i = 1:n_seqs

    % Generate a bounded random walk sequence between 0 
    % and 1 (approximately)
    y = gen_seq_brw01(nT+1, sd);

    % Downsample to get generate step sequence
    y_step = y(1:dt_step/dt_brw:end);

    % Compute load target values
    load_target = load_targets(i) .* ones(size(t_step)) ...
        + 2 .* mag_brw .* (y_step - 0.5);

    % Store input signals as struct containing time series
    inputs = struct();
    ts = timeseries(load_target, t_step);
    name = "load_target";
    ts.name = name;
    ts.TimeInfo.Units = 'seconds';
    ts.DataInfo.Interpolation.Name = 'zoh';
    ts.DataInfo.Units = 'kW';
    inputs.(name) = ts;

    % Save all sequences
    load_seqs(:, i) = load_target;

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

%% Make plot

% Summary plot of all sequences
figure(1); clf
cols = get(gca, 'ColorOrder');
stairs(t_step, load_seqs, 'LineWidth', 1);
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("Time (seconds)", 'Interpreter', 'latex')
ylabel("Target Load (kW)", 'Interpreter', 'latex')
yline(full_op_limit, '--')
ylim([700 3400])
grid on
title("Target load sequences 1 to 11", 'Interpreter', 'latex')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, 'Position', [p(1:2) figsize])
filename = "input_seqs_1.pdf";
save2pdf(fullfile(plot_dir, filename))

% %% Scenarios 6 to 10 - one step change
% for i = 1:numel(load_targets)
% 
%     % Make a sequence with one random step change, making
%     % sure the step amplitude is not zero
%     l1 = randi(length(load_targets));
%     load_target = load_targets(l1) .* ones(size(t));
%     l2 = randsample([1:l1-1 l1+1:length(load_targets)], 1);
%     t_step = t(2);
%     load_target(t >= t_step) = load_targets(l2);
% 
%     % Store input signals as struct containing time series
%     inputs = struct();
% 
%     ts = timeseries(load_target .* ones(size(t)), t);
%     name = "load_target";
%     ts.name = name;
%     ts.TimeInfo.Units = 'seconds';
%     ts.DataInfo.Interpolation.Name = 'zoh';
%     ts.DataInfo.Units = 'kW';
% 
%     inputs.(name) = ts;
% 
%     % Save simulation data file
%     filename = compose("load_sequence_%d.mat", scenario);
%     save(fullfile(data_dir, filename), "inputs")
%     fprintf("Input data file '%s' saved\n", filename)
% 
%     scenario = scenario + 1;
% end


%% Scenarios 11 to 20 - bounded random walk


% Load target level - average
mean_load_target = mean(target_load_range);

% Magnitude of BRW (kW)
mag_brw = diff(target_load_range) / 2;

% Step-size for BRW
dt_brw = 10;

% Std. dev. of BRW noise input
sd = 0.1;

nT = floor(t_stop / dt_brw);
n_seqs = length(load_targets);
assert(all(load_targets < full_op_limit(2)))
assert(all(load_targets > full_op_limit(1)))

% Sample times of BRw
t = dt_brw.*(0:nT)';

% Sample times of steps
t_step = t(1:dt_step/dt_brw:end);

load_seqs = nan(size(t_step, 1), n_seqs);

for i = 1:n_seqs

    % Generate a bounded random walk sequence between 0 
    % and 1 (approximately)
    y = gen_seq_brw01(nT+1, sd);

    % Downsample to get generate step sequence
    y_step = y(1:dt_step/dt_brw:end);

    % Compute load target values
    load_target = mean_load_target .* ones(size(t_step)) ...
        + 2 .* mag_brw .* (y_step - 0.5);

    % Store input signals as struct containing time series
    inputs = struct();
    ts = timeseries(load_target, t_step);
    name = "load_target";
    ts.name = name;
    ts.TimeInfo.Units = 'seconds';
    ts.DataInfo.Interpolation.Name = 'zoh';
    ts.DataInfo.Units = 'kW';
    inputs.(name) = ts;

    % Save all sequences
    load_seqs(:, i) = load_target;

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

%% Make plots

% Make summary plot of all sequences
figure(2); clf
cols = get(gca, 'ColorOrder');
stairs(t_step, load_seqs, 'LineWidth', 1);
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("Time (seconds)", 'Interpreter', 'latex')
ylabel("Target Load (kW)", 'Interpreter', 'latex')
yline(full_op_limit, '--')
ylim([700 3400])
grid on
title("Target load sequences 12 to 22", 'Interpreter', 'latex')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, 'Position', [p(1:2) figsize])
filename = "input_seqs_2.pdf";
save2pdf(fullfile(plot_dir, filename))


%% Make plot of selected sequence

i_sel = 12;
filename = compose("load_sequence_%d.mat", i_sel);
load(fullfile(data_dir, filename))

figure(3); clf
stairs(inputs.load_target.Time, inputs.load_target.Data, 'LineWidth', 1);
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("Time (seconds)", 'Interpreter', 'latex')
ylabel("Target Load (kW)", 'Interpreter', 'latex')
yline(full_op_limit, '--')
ylim([700 3400])
grid on
title(sprintf("Target load sequence %d", i_sel), 'Interpreter', 'latex')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, 'Position', [p(1:2) figsize])
filename = sprintf("input_seq_%d.pdf", i_sel);
save2pdf(fullfile(plot_dir, filename))