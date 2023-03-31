% Plots model predictions for multiple simulations
%
% Make plots for previous simulations by specifying the 
% variables below and running this script. Note: only the
% files of the last simulation in each simulation directory
% are saved so you can only make theseplots for the last 
% simulation.
%

addpath("yaml")
addpath("plot-utils")

% Setup
sim_names = ["test_sim_gpr1" "test_sim_gpr2" "test_sim_gpr3"];
labels = ["GPR1" "GPR2" "GPR3"];
sims_dir = "simulations";
i_sim = 0;    % only used if multiple sims run

% Directory where plots will be saved
plot_dir = "plots";
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

sim_names = string(sim_names);
n_sims = length(sim_names);
assert(size(sim_names, 1) == 1)
load_data = cell(1, n_sims);
power_data = cell(1, n_sims);
metrics_summaries = cell(1, n_sims);
for i = 1:n_sims
    sim_name = sim_names{i};
    % Directory where config files are stored
    sim_spec_dir = fullfile(sims_dir, sim_name, "sim_specs");

    % Directory where simulation results files are stored
    results_dir = fullfile(sims_dir, sim_name, "results");
    fprintf("Getting simulation results from '%s' for plotting\n", ...
        results_dir)

    % Load sim_spec file
    filepath = fullfile(sim_spec_dir, "sim_spec.yaml");
    fprintf("Loading simulation spec from '%s'\n", filepath)
    sim_spec = yaml.loadFile(filepath, "ConvertToArray", true);
    
    % Load optimizer configuration file
    filepath = fullfile(sim_spec_dir, sim_spec.optimizer.config_filename);
    fprintf("Loading optimizer configuration from '%s'\n", filepath)
    opt_config = yaml.loadFile(filepath, "ConvertToArray", true);

    % Load optimizer output data file
    filespec = fullfile(sims_dir, sim_name, "results", ...
            "load_opt_out.mat");
    load(filespec)
    machine_names = string(fieldnames(opt_config.machines))';
    n_machines = numel(machine_names);
    
    % Load simulation output data file
    filespec = fullfile(sims_dir, sim_name, "results", "sim_out.mat");
    load(filespec)

    % Load optimum power results file
    filename = sim_spec.simulation.outputs.min_power_data;
    power_opt_table = readtable(fullfile("results", filename));
    
    % Set up linear interpolation function
    power_opt_func = @(load) interp1(power_opt_table.TotalLoadTarget, ...
        power_opt_table.TotalPower, load);

    % Calculate ideal power at all simulation times
    power_ideal = power_opt_func(sim_out.load_actual.Data);

    % Save data for plotting below
    load_data{1, i} = [
        sim_out.load_actual.Time ...
        sim_out.load_target.Data ...
        sim_out.load_actual.Data ...
    ];
    power_data{1, i} = [
        sim_out.total_power.Time ...
        power_ideal ...
        sim_out.total_power.Data ...
        opt_config.optimizer.params.PMax.*ones(size(sim_out.tout)) ...
    ];

    % Save key metrics for the comparison plot later
    filename = sprintf("%s_metrics_%03d.csv", sim_name, i_sim);
    metrics_summaries{i} = readtable(fullfile(results_dir, filename));

end


%% Plot total load and power time series

figure(1); clf

ax1 = subplot(2, 1, 1);
% load_data contains Time Target Actual ...
for i = 1:n_sims
    data = load_data{:, i};
    t = data(:, 1);
    Y = data(:, 3);
    plot(t, Y, 'Linewidth', 1); hold on
    if i == n_sims
        load_target = data(:, 2);
        plot(t, load_target, 'k-');
    end
end
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("Time (seconds)", 'Interpreter', 'latex');
leg_labels = [labels ["Target"]];
ylabel("Total load (kW)", 'Interpreter', 'latex');
legend(leg_labels, 'Interpreter', 'latex', 'location', 'best');
grid on

ax2 = subplot(2, 1, 2);
% power_data contains Time Ideal Actual PMax
for i = 1:n_sims
    data = power_data{:, i};
    t = data(:, 1);
%     if i == 1  % ideal is specific to each opt scenario
%         power_ideal = data(:, 2);
%         plot(t, power_ideal); hold on
%     end
    Y = data(:, 3);
    plot(t, Y, 'Linewidth', 1); hold on
    if i == n_sims
        power_limit = data(:, 4);
        plot(t, power_limit, 'k--');
    end
end
set(gca, 'TickLabelInterpreter', 'latex')
xlabel("Time (seconds)", 'Interpreter', 'latex');
leg_labels = [labels ["Limit"]];
ylabel("Total power (kW)", 'Interpreter', 'latex');
legend(leg_labels, 'Interpreter', 'latex', 'location', 'best');
grid on

linkaxes([ax1 ax2], 'x')

% Resize plot and save as pdf
set(gcf, 'Units', 'inches');
p = get(gcf, 'Position');
figsize = [3.5 4.5];
set(gcf, 'Position', [p(1:2) figsize])
filename = sprintf("sim_mult_load_power_tsplot_%d.pdf", n_sims);
save2pdf(fullfile(plot_dir, filename))


%% Plot key metrics over time for all sims

figure(2); clf
make_metrics_plot_mult(metrics_summaries, labels);

filename = sprintf("mult_sims_metrics_plot_%d.pdf", n_sims);
save2pdf(fullfile(plot_dir, filename))

return


%% Plot model predictions over time

% Max number of columns to include in figure
n_max = 5;

figure(10); clf
for i = 1:n_machines
    machine = machine_names{i};

    % Iterations when model update was made
    iters = LOData.Iteration(logical(LOData.ModelUpdates(:, i)));

    % Times when model update was made
    times = LOData.Time(iters)';

    % Add time t=0 if there was no model update then so that
    % initial model predictions are plotted
    if times(1) > 0
        times = [0 times];
    end

    % Only plot up to a maximum of n_max model updates
    n_times = min(length(times), n_max);

    if n_times > 0

        y_labels = "Power";
        line_label = "predicted";
        %area_label = compose("%.f\%CI", );  TODO: add confidence value
        area_label = "CI";
        x_label = "Load";

        model_preds = cell(1, n_times);

        % First load all data for this model to establish y-axis
        % limits for all plots in this row.
        y_lim = [inf -inf];
        for j = 1:n_times

            % Always plot the final plot - NOTE: see same below
            if j == n_times
                t = times(end);
            else
                t = times(j);
            end
    
            % Load predictions
            filename = compose("%s_%s_preds_%.0f.csv", sim_name, machine, t);
            model_preds{j} = readtable(fullfile(sims_dir, sim_name, ...
                        "results", filename));

            % Update min/max range
            y_lim(1) = min(min(model_preds{j}{:, 'y_int_1'}), y_lim(1));
            y_lim(2) = max(max(model_preds{j}{:, 'y_int_2'}), y_lim(2));

        end

        for j = 1:n_times

            % Always plot the final plot
            if j == n_times
                t = times(end);
            else
                t = times(j);
            end
    
            % Plot predictions and training data points
            subplot(n_machines, 5, 5*(i-1)+j);
            make_statplot( ...
                model_preds{j}{:, 'y_mean'}, ...
                model_preds{j}{:, 'y_int_1'}, ...
                model_preds{j}{:, 'y_int_2'}, ...
                model_preds{j}{:, 'op_interval'}, ...
                x_label, y_labels, line_label, area_label, y_lim);

            % Index of current data point
            k = find(LOModelData.Machines.(machine).Time == t);
            if isempty(k)
                % If there was no model update at t = 0, make
                % plot with pre-training data
                k_updates = find(~isnan(LOModelData.Machines.(machine).Time));
                k = max(k_updates(1) - 1, 0);
            end

            % Add all previous training data points to plot
            if k > 0
                x = LOModelData.Machines.(machine).X(1:k);
                y = LOModelData.Machines.(machine).Y(1:k);
                plot(x, y, 'k.', 'MarkerSize', 10)
            end
            xlim([min(model_preds{j}{:, 'op_interval'}) ...
                  max(model_preds{j}{:, 'op_interval'})])
            text(0.05, 0.9, compose("$t=%d$", t), 'Units', 'normalized', ...
                'Interpreter', 'latex')
            title(escape_latex_chars(opt_config.machines.(machine).name), ...
                'Interpreter', 'latex')
            hLeg = findobj(gcf, 'Type', 'Legend');
%             leg_labels = hLeg.String;
%             hLeg = legend([leg_labels(1:2) {'data'}], 'Location', 'southeast');
%             if j < n_times
%                 set(hLeg, 'visible', 'off')
%             end
            % Use this to turn legend off:
            set(hLeg, 'visible', 'off')
        end
    end
end

grid on

% Resize figure appropriately
s = get(gcf, 'Position');
set(gcf, 'Position', [s(1:2) -30+210*5 -30+180*n_machines]);

% Save as pdf
filename = compose("model_preds_%.0f.pdf", t);
save2pdf(fullfile(sims_dir, sim_name, "plots", filename))
