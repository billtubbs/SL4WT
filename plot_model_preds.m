% Plots model predictions for last simulation
%
% Make sure that sim_name is set to the name of the simulation
%
%sim_name = "test_sim"
%

addpath("yaml")
addpath("plot-utils")

% Load configuration file
filepath = fullfile("simulations", sim_name, "opt_config.yaml");
fprintf("Loading optimizer configuration from '%s'\n", filepath)
config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load simulation data mat file
filespec = fullfile("simulations", sim_name, "results", ...
        "load_opt.mat");
load(filespec)
n_max = 5;  % Max number of columns

machine_names = string(fieldnames(config.machines))';
n_machines = numel(machine_names);

figure(10); clf
for i = 1:n_machines
    machine = machine_names{i};

    % Iterations when model update was made
    iters = LOData.Iteration(logical(LOData.ModelUpdates(:, i)));

    % Times when model update was made
    times = LOData.Time(iters)';

    % Include t=0 so that initial model predictions are plotted
    times = [0 times];

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
            t = times(j);
    
            % Load predictions
            filename = compose("%s_%s_preds_%.0f.csv", sim_name, machine, t);
            model_preds{j} = readtable(fullfile("simulations", sim_name, ...
                        "results", filename));

            % Update min/max range
            y_lim(1) = min(min(model_preds{j}{:, 'y_int_1'}), y_lim(1));
            y_lim(2) = max(max(model_preds{j}{:, 'y_int_2'}), y_lim(2));
            
        end

        for j = 1:n_times
            t = times(j);

            % Plot predictions and training data points
            subplot(n_machines, 5, 5*(i-1)+j);
            make_statplot( ...
                model_preds{j}{:, 'y_mean'}, ...
                model_preds{j}{:, 'y_int_1'}, ...
                model_preds{j}{:, 'y_int_2'}, ...
                model_preds{j}{:, 'op_interval'}, ...
                y_labels, line_label, area_label, x_label, y_lim)

            % Index of current data point
            k = find(LOModelData.(machine).Time == t);

            % Add all previous training data points to plot
            x = LOModelData.Machines.(machine).Load(1:k);
            y = LOModelData.Machines.(machine).Power(1:k);
            plot(x, y, 'k.', 'MarkerSize', 10)
            text(0.05, 0.9, compose("$t=%d$", t), 'Units', 'normalized', ...
                'Interpreter', 'latex')
            title(config.machines.(machine).name, 'Interpreter', 'latex')
            hLeg = findobj(gcf, 'Type', 'Legend');
            leg_labels = hLeg.String;
            legend([leg_labels(1:2) {'data'}], 'Location', 'southeast')
            if j < n_times
                set(hLeg, 'visible', 'off')
            end
        end
    end
end

grid on

% Size figure appropriately
s = get(gcf, 'Position');
set(gcf, 'Position', [s(1:2) -30+210*5 -30+180*n_machines]);
filename = compose("model_preds_%.0f.pdf", t);
save2pdf(fullfile("simulations", sim_name, "plots", filename))
