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

% Number of total load points to find optimum solution
n_pts = 501;

% Number of random searches to do for optimizer initial
% point
n_searches = 50;

%% Load configuration file

% Load simulation config file with machine parameters
filename = "test_sys_config.yaml";
sys_config = yaml.loadFile(fullfile(test_dir, test_data_dir, filename), ...
    "ConvertToArray", true);

machine_names = fieldnames(sys_config.equipment);
n_machines = numel(machine_names);

% Constraints: lower and upper bounds of load for each machine
op_limits = cell2mat( ...
    cellfun(@(name) sys_config.equipment.(name).params.op_limits, ...
        machine_names, 'UniformOutput', false) ...
);

% Total load range
min_load = sum(op_limits(:, 1));
max_load = sum(op_limits(:, 2));

% Test function to calculate total power of all machines
min_power = calc_total_power(op_limits(:, 1), sys_config.equipment);
assert(round(min_power, 4) ==  753.4969)
max_power = calc_total_power(op_limits(:, 2), sys_config.equipment);
assert(round(max_power, 4) ==  1978.7627)

% Leave a gap between lower and upper limit because 
% optimizing in this space is tricky (very few solutions)
load_targets = linspace(min_load+50, max_load-50, n_pts)';


%% If results already exist load them from file

filename = compose("min_power_load_solutions_opt%d_%d.csv", ...
    n_searches, n_pts);

if exist(fullfile(results_dir, filename), 'file')

    results = readtable(fullfile(results_dir, filename));
    fprintf("Existing results laoded from file '%s'\n", filename)
    load_targets_before = load_targets;
    load_targets = results.TotalLoadTarget;
    assert(max(abs(load_targets_before - load_targets(2:end-1))) < 1e-12);

    load_targets = results.TotalLoadTarget;
    loads = results{:, {'MachineLoad1', 'MachineLoad2', ...
            'MachineLoad3', 'MachineLoad4', 'MachineLoad5'}};
    total_powers = results.TotalPower;

else

    % Test function to calculate power of one machine
    machine = machine_names{1};
    sigma_M = 0;  % no noise
    params = sys_config.equipment.(machine).params;
    load = 500;
    power = sample_op_pts_poly(load, params, sigma_M);
    assert(round(power, 4) == 149.9006)

    % Create function to calculate total power given loads
    % of machines 1-4 and total power target
    calc_total_power2 = @(loads, load_target) calc_total_power( ...
        [loads(1:n_machines-1); ...
         load_target-sum(loads(1:n_machines-1))], ...
        sys_config.equipment ...
    );

    n_sols = numel(load_targets);
    load_sols = nan(n_sols, n_machines - 1);
    total_powers = nan(n_sols, 1);
    opt_flags = nan(n_sols, 1);
    n_unique = nan(n_sols, 1);
    
    % Choose an initial point
    best_load = [56 237 194 194]';
    for i = 1:length(load_targets)
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
    
        % Do random search of initial points, including the solution
        % from the previous iteration
        % Choose initial condition for solver
        x0 = best_load;  % best solution from previous iteration
        %x0 = [60 240 200 200]';
        %x0 = [220 537 795 194]';
        if n_searches > 0
            % Add random initialization points
            % Start from a point inside operating limits
            r = (load_target - sum(op_limits(:, 1))) ...
                / sum(diff(op_limits, [], 2));
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

    % Save results
    var_names = {'TotalLoadTarget', 'MachineLoad1', 'MachineLoad2', ...
            'MachineLoad3', 'MachineLoad4', 'MachineLoad5', 'TotalPower'};

    % Add the lower and upper limits to the data before plotting
    results = [ ...
        min_load      op_limits(:,1)'  min_power;
        load_targets  loads            total_powers;
        max_load      op_limits(:,2)'  max_power ...
    ];
    results = array2table(results, 'VariableNames', var_names);

    writetable(results, fullfile(results_dir, filename))
    fprintf("Results saved to file '%s'\n", filename)

    figure(1); clf

    % Make histogram of number of unique solutions
    bar(load_targets, n_unique, 'LineStyle', 'none')
    ylabel("No. of unique solutions")
    grid on
    title("Number of unique solutions")
    p = get(gcf, 'Position');
    set(gcf, 'Position', [p(1:2) 420 160])
    xlabel("Load target (kW)")

    filename = "optimum_loads_n_unique.pdf";
    save2pdf(fullfile(plot_dir, filename))

end

% Calculate a benchmark for comparison
% E.g. Assume all 5 machines are adjusted linearly in
% proportion to the total load target.

load_target_ratios = (load_targets - min_load) ./ (max_load - min_load);
loads_prop = op_limits(:, 1)' + diff(op_limits, [], 2)' .* load_target_ratios;
assert(max(abs(sum(loads_prop, 2) - load_targets)) <  1e-10)
total_powers_prop = nan(size(load_targets));
for i = 1:length(load_targets)
    total_powers_prop(i) = calc_total_power( ...
        loads_prop(i, :)', ...
        sys_config.equipment ...
    );
end
assert(all(min(total_powers_prop - total_powers) > -1e-12))

% Calculate maximum energy saving from optimization
[max_diff, i_max] = max(total_powers_prop - total_powers);
fprintf("Largest difference: %.1f kW at %.1f kW\n", ...
    max_diff, load_targets(i_max))

% Calculate maximum load that does not exceed the power limit
PMax = 1580;

% With proportional load allocation
i_ex = find(total_powers_prop > 1580);
load_max_prop = interp1( ...
    total_powers_prop(i_ex(1)-1:i_ex(1)), ...
    load_targets(i_ex(1)-1:i_ex(1)), ...
    PMax ...
);
fprintf("Highest possible load, prop.: %.1f kW\n", load_max_prop)

% With optimized load allocation
i_ex = find(total_powers > 1580);
load_max_opt = interp1( ...
    total_powers(i_ex(1)-1:i_ex(1)), ...
    load_targets(i_ex(1)-1:i_ex(1)), ...
    PMax ...
);
fprintf("Highest possible load, optimized: %.1f kW\n", load_max_opt)
fprintf("Difference: %.1f kW\n", load_max_opt - load_max_prop)


%% Make plots

loads_sorted = [loads(:, 1:2) sort(loads(:, 3:5), 2)];

% Line plot of loads of each machine
figure(2); clf
subplot(2, 1, 1)
y_lims = axes_limits_with_margin(reshape(op_limits, [], 1), 0.05);
plot(load_targets, loads_sorted, 'Linewidth', 2)
xlim(load_targets([1 end]))
ylim(y_lims)
xlabel("Load target (kW)", 'Interpreter', 'latex')
ylabel("Machine load (kW)", 'Interpreter', 'latex')
set(gca, 'TickLabelInterpreter', 'latex')
labels = compose("machine %d", 1:5);
legend(labels, 'Location', 'best', 'Interpreter', 'latex')
grid on
title("(a) Optimum machine loads", 'Interpreter', 'latex')

subplot(2, 1, 2)
plot(load_targets, total_powers ./ load_targets, 'Linewidth', 2)
xlim(load_targets([1 end]))
xlabel("Load target (kW)", 'Interpreter', 'latex')
ylabel("Specific power (kW/kW)", 'Interpreter', 'latex')
set(gca, 'TickLabelInterpreter', 'latex')
grid on
title("(b) Overall specific power consumption", 'Interpreter', 'latex')

filename = "optimum_loads_plot.pdf";
save2pdf(fullfile(plot_dir, filename))


%% Area plot of loads of each machine - for published paper
figure(3); clf

ax1 = subplot(2, 1, 1);
area(load_targets, loads_sorted)
xlim(load_targets([1 end]))
%xlabel("Load target (kW)", 'Interpreter', 'latex')
ylabel("Load (kW)", 'Interpreter', 'latex')
set(gca, 'TickLabelInterpreter', 'latex')
labels = compose("%d", 1:5);
lh = legend(labels, 'Location', 'northwest', 'Interpreter', 'latex', 'NumColumns', 4);
lp = get(lh, 'Position');
set(lh, 'Position', [0.16 0.83 0.5 0.08])
grid on
title("(a) Optimum machine loads", 'Interpreter', 'latex')
set(gca,'fontsize', 8)

ax2 = subplot(2, 1, 2);
plot(load_targets, total_powers_prop ./ load_targets, 'Linewidth', 1)
hold on
plot(load_targets, total_powers ./ load_targets, 'Linewidth', 1)
colors = get(gca, 'ColorOrder');
load_minmax = load_targets([1 end]);

% Draw power limit curve
plot(load_targets, PMax ./ load_targets, 'Color', [0.4 0.4 0.4])

% Add points at intersections
%plot(load_max_prop, PMax/load_max_prop, '.', 'Color', colors(1, :))
%plot(load_max_opt, PMax/load_max_opt, '.', 'Color', colors(2, :))

% Add annotated arrow
% se_pt = 0.75;
% load_intersect = interp1(PMax ./ load_targets, load_targets, se_pt);
% ar = annotation('textarrow');
% ar.Parent = gca;
% ar.X = load_intersect-[220 0];
% ar.Y = [se_pt se_pt];
% ar.String = "Power limit";
% ar.Interpreter = 'latex';
% ar.HeadLength = 5;
% ar.HeadWidth = 5;
% ar.FontSize = 8;
% This doesn't work:
% annotation('textarrow', ...
%     load_max_prop-[100 0], [0.74 0.68], ...
%     'String','Max. loads', ...
%     'Units',)
xlim(load_targets([1 end]))
ylim([0.6 0.9])
xlabel("Total load target (kW)", 'Interpreter', 'latex')
ylabel("Sp. energy (kW/kW)", 'Interpreter', 'latex')
set(gca, 'TickLabelInterpreter', 'latex')
grid on
title("(b) Overall specific power consumption", 'Interpreter', 'latex')
legend({'Prop. loads', 'Opt. loads', 'Power limit'}, ...
    'Location', 'northeast', 'Interpreter', 'latex')
set(gca,'fontsize', 8)

linkaxes([ax1 ax2], 'x')

% Resize
p = get(gcf, 'Position');
set(gcf, 'Units', 'inches', ...
    'Position', [3, 4, 3.5, 3.5], ...
    'PaperUnits', 'inches', ...
    'PaperSize', [3.5, 3.5] ...
)

filename = "optimum_loads_plot_area_3-5in.pdf";
save2pdf(fullfile(plot_dir, filename))


