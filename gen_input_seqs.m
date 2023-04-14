% Generate load target input sequences for simulations
% TODO: generate 'seed' data points for model training.
%

clear all

addpath("yaml")

seed = 0;
rng(seed)

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

% Count scenarios
scenario = 1;

% Step length (seconds)
dt_step = 250;

% Duration
t_stop = 16*dt_step;

% Lower and upper values
target_load_range = [1000 3000];

load_seqs_sets = cell(2, 1);


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
    filename = compose("load_sequence_%02d.mat", scenario);
    save(fullfile(data_dir, filename), "inputs")
    fprintf("Input data file '%s' saved\n", filename)

    scenario = scenario + 1;
end
load_seqs_sets{1} = load_seqs;


%% Make plot

% Summary plot of all sequences
figure(1); clf
cols = get(gca, 'ColorOrder');
for i = 1:size(load_seqs, 2)
    switch i
        case 1
            lw = 2;
            c = 1;
        otherwise
            lw = 1;
            c = 2;
    end
    % Unfortunately, transparency doesn't work with stair plots
    stairs(t_step, load_seqs(:, i), 'LineWidth', lw, ...
        'Color', [cols(c, :) 0.1]); hold on
end
text(100, full_op_limit(2)+110, "Op. limits", 'Interpreter', 'latex')
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("Time (seconds)", 'Interpreter', 'latex')
ylabel("Target load (kW)", 'Interpreter', 'latex')
yline(full_op_limit, '--')
ylim([700 3400])
grid on
legend("seq. 1", 'Interpreter', 'latex')
title("Sequences 1 to 11", 'Interpreter', 'latex')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, 'Position', [p(1:2) figsize])
filename = "input_seqs_1.pdf";
save2pdf(fullfile(plot_dir, filename))


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
    filename = compose("load_sequence_%02d.mat", scenario);
    save(fullfile(data_dir, filename), "inputs")
    fprintf("Input data file '%s' saved\n", filename)

    scenario = scenario + 1;
end
load_seqs_sets{2} = load_seqs;


%% Make plots

% Make summary plot of all sequences
figure(2); clf
cols = get(gca, 'ColorOrder');
%stairs(t_step, load_seqs, 'LineWidth', 1);
for i = 1:size(load_seqs, 2)
    % Unfortunately, transparency doesn't work with stair plots
    switch i
        case 1
            lw = 2;
            c = 1;
        otherwise
            lw = 1;
            c = 2;
    end
    stairs(t_step, load_seqs(:, i), 'LineWidth', lw, ...
        'Color', [cols(c, :) 0.1]); hold on
end
text(100, full_op_limit(2)+110, "Op. limits", 'Interpreter', 'latex')
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("Time (seconds)", 'Interpreter', 'latex')
ylabel("Target load (kW)", 'Interpreter', 'latex')
yline(full_op_limit, '--')
ylim([700 3400])
grid on
legend("seq. 12", 'Interpreter', 'latex')
title("Sequences 12 to 22", 'Interpreter', 'latex')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 2.5];
set(gcf, 'Position', [p(1:2) figsize])
filename = "input_seqs_2.pdf";
save2pdf(fullfile(plot_dir, filename))


%% Make combined figure with both plots

figure(3); clf
cols = get(gca, 'ColorOrder');

tiledlayout(1, 2)


i_seqs = [nan 0];
for i_set = 1:2
    load_seqs = load_seqs_sets{i_set};
    i_seqs = [i_seqs(2) i_seqs(2)+size(load_seqs,2)];

    nexttile;
    %stairs(t_step, load_seqs, 'LineWidth', 1);
    for i = 1:size(load_seqs, 2)
        % Unfortunately, transparency doesn't work with stair plots
        switch i
            case 1
                lw = 2;
                c = 1;
            otherwise
                lw = 1;
                c = 2;
        end
        stairs(t_step, load_seqs(:, i), 'LineWidth', lw, ...
            'Color', [cols(c, :) 0.1]); hold on
    end
    text(100, full_op_limit(2)+110, "Op. limits", 'Interpreter', 'latex')
    set(gca, 'TickLabelInterpreter', 'latex')
    xlabel("Time (seconds)", 'Interpreter', 'latex')
    ylabel("Target load (kW)", 'Interpreter', 'latex')
    yline(full_op_limit, '--')
    ylim([700 3400])
    grid on
    legend("seq. 12", 'Interpreter', 'latex')
    title_text = sprintf("(%s) Sequences %d to %d", char(96+i_set), i_seqs);
    title(title_text, 'Interpreter', 'latex')

end

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [8 2.5];
set(gcf, 'Position', [p(1:2) figsize])
filename = "input_seqs_1-2.pdf";
save2pdf(fullfile(plot_dir, filename))


%% Make plot of one selected sequence

i_sel = 12;
filename = compose("load_sequence_%d.mat", i_sel);
load(fullfile(data_dir, filename))

figure(4); clf
stairs(inputs.load_target.Time, inputs.load_target.Data, 'LineWidth', 1);
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("Time (seconds)", 'Interpreter', 'latex')
ylabel("Target load (kW)", 'Interpreter', 'latex')
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


%% Produce 22 sets of initial training points for each machine

rng(seed+1)

% Choose where to sample points (in % of full operating range)
%x_sample_range = [0 1];
x_sample_range = [0.05 0.15];  % used this for INDIN paper
%x_sample_range = [0.4 0.6];
%x_sample_range = [0.8 1];

% Number of points per data set
n_samples = 3;

% Number of data sets to generate
n = 22;

% Generate n sets of randomized training data per machine
training_data = cell(n, n_machines);

machine_names = string(fieldnames(sys_config.equipment));
n_machines = length(machine_names);

for i = 1:n
    for m = 1:n_machines
        machine = machine_names(m);
        machine_config = sys_config.equipment.(machine);

        % Measurement noise level
        sigma_M = sys_config.equipment.(machine).params.sigma_M;

        % Sample random load points from defined range
        X_sample = random_sample_uniform( ...
            machine_config.params.op_limits, ...
            x_sample_range, ...
            n_samples ...
        );

        % Sample from machine load-power models (with measurement noise)
        Y_sample = sample_op_pts_poly( ...
            X_sample, ...
            machine_config.params, ...
            sigma_M ...
        );

        training_data = array2table( ...
            [X_sample Y_sample], ...
            "VariableNames", {'Load', 'Power'}  ...
        );

        filename = sprintf("machine_%d_data_%02d.csv", m, i);
        writetable(training_data, fullfile(data_dir, filename))
        fprintf("Training data file '%s' saved\n", filename)

    end
end