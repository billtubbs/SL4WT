% Analyse problem to determine optimum compressor load sharing solution

clear variables

addpath("yaml")
addpath("plot-utils")
addpath("RandPtsInLinearConstraints")

rng(0)

test_dir = "tests";
test_data_dir = "data";
results_dir = "results";
plot_dir = "plots";
if ~exist(results_dir, 'dir')
    mkdir(results_dir)
end
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

% Load simulation config file with machine parameters
filename = "test_sim_config.yaml";
sim_config = yaml.loadFile(fullfile(test_dir, test_data_dir, filename), ...
    "ConvertToArray", true);

machine_names = fieldnames(sim_config.machines);
n_machines = numel(machine_names);

% Constraints: lower and upper bounds of load for each machine
op_limits = cell2mat( ...
    cellfun(@(name) sim_config.machines.(name).params.op_limits, ...
        machine_names, 'UniformOutput', false) ...
);

% Test function to calculate power of one machine
machine = machine_names{1};
sigma_M = 0;  % no noise
params = sim_config.machines.(machine).params;
load = 500;
power = sample_op_pts_poly(load, params, sigma_M);
assert(round(power, 4) == 149.9006)

% Total load range
min_load = sum(op_limits(:, 1));
max_load = sum(op_limits(:, 2));

% Test function to calculate total power of all machines
min_power = calc_total_power(op_limits(:, 1), sim_config.machines);
assert(round(min_power, 4) ==  753.4969)
max_power = calc_total_power(op_limits(:, 2), sim_config.machines);
assert(round(max_power, 4) ==  1978.7627)
load_targets = linspace(min_load+50, max_load-50, 101)';

% Create function to calculate total power given loads
% of machines 1-4 and total power target
calc_total_power2 = @(loads, load_target) calc_total_power( ...
    [loads(1:n_machines-1); ...
     load_target-sum(loads(1:n_machines-1))], ...
    sim_config.machines ...
);

n_sols = numel(load_targets);
load_sols = nan(n_sols, n_machines - 1);
total_powers = nan(n_sols, 1);
opt_flags = nan(n_sols, 1);
n_unique = nan(n_sols, 1);

% Choose an initial point
best_load = [56 237 194 194]';
for i = 1:numel(load_targets)
    load_target = load_targets(i);
    
    ObjFun = @(loads) calc_total_power2(loads, load_target);

    % Optimizer options
    options = optimoptions('fmincon', ...
        'SubproblemAlgorithm', "cg", ...
        'MaxIterations', 10000, ...
        'MaxFunctionEvaluations', 10000, ...
        'OptimalityTolerance', 1e-6, ...
        'ConstraintTolerance', 1e-6, ...
        'Display', 'final-detailed' ...
    );

    % Do a random search of initial points, including the solution
    % from the previous iteration
    n_searches = 50;
    % Choose initial condition for solver
    x0 = best_load;  % best solution from previous iteration
    %x0 = [60 240 200 200]';
    %x0 = [220 537 795 194]';
    if n_searches > 0
        % Add random initialization points
        % Start from a point inside operating limits
        r = (load_target - sum(op_limits(:, 1))) / sum(diff(op_limits, [], 2));
        xr = op_limits(:, 1) + r .* diff(op_limits, [], 2);
        X0 = RandPtsInLinearConstraints( ...
                n_searches, ...
                xr, ...
                ones(1, 5), ...
                load_target, ...
                op_limits(:, 2), ...
                op_limits(:, 1), ...
                [0 0 0 0 0], ...
                0 ...
            );
        X0 = [x0(1:4)'; X0(1:4, :)'];  % remove final machine loads
    end

    best_power = inf;
    unique_sols = double.empty(0, n_machines-1);
    for j = 1:size(X0,1)

        % Initial point
        x0 = X0(j, :)';

        % Run the optimizer
        A = [ones(1,4); -ones(1,4)];
        B = [load_target-op_limits(5,1);
             op_limits(5,2)-load_target];
        [load_sol, power_sol, flag] = fmincon( ...
            ObjFun, ...
            x0, ...
            A, B, ...  % A*X <= B
            [], [], ...  % Aeq, Beq: Aeq*X = Beq
            op_limits(1:4, 1), ...
            op_limits(1:4, 2), ...
            [], ...
            options ...
        );
        opt_flags(j) = flag;
        if flag < 1
            warning(compose("optimizer flag is %d.", flag))
        end

        % Check constraints met
        assert(load_target - sum(load_sol) >= op_limits(n_machines, 1))
        assert(load_target - sum(load_sol) <= op_limits(n_machines, 2))

        if ~ismember(round(load_sol', 2), unique_sols, 'rows')
            unique_sols = [unique_sols; round(load_sol', 2)];
        end

        if power_sol < best_power
            best_load = load_sol;
            best_power = power_sol;
        end
    end
    n_unique(i) = size(unique_sols, 1);
    load_sols(i, :) = best_load;
    total_powers(i) = best_power;

end
loads = [load_sols load_targets-sum(load_sols, 2)];

% print total power
fprintf("Cumulative power: %g\n", sum(total_powers));

%% Save results
results = array2table([load_targets loads total_powers], ...
    'VariableNames', {'TotalLoadTarget', 'MachineLoad1', 'MachineLoad2', ...
        'MachineLoad3', 'MachineLoad4', 'MachineLoad5', 'TotalPower'});
filename = "min_power_load_solutions.csv";
writetable(results, fullfile(results_dir, filename))
fprintf("Results saved to file '%s'\n", filename)


%% Make plot

y_lims = axes_limits_with_margin(reshape(op_limits, [], 1), 0.05);

loads_sorted = [loads(:, 1:2) sort(loads(:, 3:5), 2)];

figure(1); clf
subplot(2, 1, 1)
plot(load_targets, loads_sorted, '.-')
xlim(load_targets([1 end]))
ylim(y_lims)
xlabel("Load target (kW)", 'Interpreter', 'latex')
ylabel("Machine load (kW)", 'Interpreter', 'latex')
set(gca, 'TickLabelInterpreter', 'latex')
labels = compose("machine %d", 1:5);
legend(labels, 'Location', 'best', 'Interpreter', 'latex')
grid on
title("Optimum Machine Loads", 'Interpreter', 'latex')

subplot(2, 1, 2)
plot(load_targets, total_powers ./ load_targets, 'Linewidth', 2)
xlim(load_targets([1 end]))
xlabel("Load target (kW)", 'Interpreter', 'latex')
ylabel("Specific energy (kW/kW)", 'Interpreter', 'latex')
set(gca, 'TickLabelInterpreter', 'latex')
grid on
title("Overall Specific Energy Consumption", 'Interpreter', 'latex')

filename = "optimum_loads_plot.pdf";
save2pdf(fullfile(plot_dir, filename))

figure(2); clf

bar(load_targets, n_unique, 'LineStyle', 'none')
ylabel("No. of unique solutions")
grid on
title("Number of unique solutions")
p = get(gcf, 'Position');
set(gcf, 'Position', [p(1:2) 420 160])
xlabel("Load target (kW)")

filename = "optimum_loads_n_unique.pdf";
save2pdf(fullfile(plot_dir, filename))
