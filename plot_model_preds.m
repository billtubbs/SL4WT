% Plots model predictions for last simulation
%
% Make sure that sim_name is set to the name of the simulation
%
%sim_name = "test_sim"
%

addpath("yaml")
addpath("plot-utils")

% Directory where config files are stored
sim_spec_dir = "sim_specs";

% Load configuration file
filepath = fullfile("simulations", sim_name, sim_spec_dir, ...
    "opt_config.yaml");
fprintf("Loading optimizer configuration from '%s'\n", filepath)
config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load optimizer output data file
filespec = fullfile("simulations", sim_name, "results", ...
        "load_opt_out.mat");
load(filespec)
machine_names = string(fieldnames(config.machines))';
n_machines = numel(machine_names);

% Load simulation output data file
filespec = fullfile("simulations", sim_name, "results", "sim_out.mat");
load(filespec)

fprintf("Plotting simulation results from '%s'\n", ...
    fullfile("simulations", sim_name, "results"))


%% Plot total load and power time series

% Calculate ideal power at all simulation times
power_ideal = opt_load(sim_out.load_actual.Data);

figure(1); clf

ax1 = subplot(2, 1, 1);
Y = [sim_out.load_target.Data sim_out.load_actual.Data];
x = sim_out.load_actual.Time;
x_label = "Time (s)";
y_labels = ["Target" "Actual"];
make_tsplot(Y, x, y_labels, x_label)
ylabel("Total load (kW)")

ax2 = subplot(2, 1, 2);
Y = [
    power_ideal ...
    sim_out.total_power.Data ...
    opt_config.optimizer.params.PMax.*ones(size(sim_out.tout)) ...
];
x = sim_out.total_power.Time;
x_label = "Time (s)";
y_labels = ["Ideal" "Actual" "Maximum"];
make_tsplot(Y, x, y_labels, x_label)
ylabel("Total power (kW)")

linkaxes([ax1 ax2], 'x')


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
            model_preds{j} = readtable(fullfile("simulations", sim_name, ...
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
                x_label, y_labels, line_label, area_label, y_lim)

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
            title(escape_latex_chars(config.machines.(machine).name), ...
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
save2pdf(fullfile("simulations", sim_name, "plots", filename))
