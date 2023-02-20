% Plots model predictions for last simulation
%
% Make sure that sim_name is set to the name of the simulation
%
%sim_name = "test_sim"
%

addpath("yaml")
addpath("plot-utils")

% Load configuration file
filepath = fullfile(sim_dir, sim_name, "opt_config.yaml");
fprintf("Loading optimizer configuration from '%s'\n", filepath)
config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load simulation data mat file
filespec = fullfile("simulations", sim_name, "results", ...
        "load_opt.mat");
load(filespec)

machine_names = string(fieldnames(config.machines))';
n_machines = numel(machine_names);
for i = 1:n_machines
    machine = machine_names{i};

    % Iterations when model update was made
    iters = LOData.Iteration(logical(LOData.ModelUpdates(:, i)));

    % Times when model update was made
    times = LOData.Time(iters)';

    % Include t=0 so that initial model predictions are plotted
    times = [0 times];
    n_times = length(times);

    if n_times > 0
        figure(10+i); clf
        y_labels = "Power";
        line_label = "predicted";
        %area_label = compose("%.f\%CI", );  TODO: add confidence value
        area_label = "CI";
        x_label = "Load";

        for j = 1:n_times
            t = times(j);
    
            % Load predictions
            filename = compose("%s_%s_preds_%.0f.csv", sim_name, machine, t);
            model_preds = readtable(fullfile("simulations", sim_name, ...
                        "results", filename));
    
            % Plot predictions and training data points
            subplot(1, n_times, j);
            make_statplot( ...
                model_preds{:, 'y_mean'}, ...
                model_preds{:, 'y_int_1'}, ...
                model_preds{:, 'y_int_2'}, ...
                model_preds{:, 'op_interval'}, ...
                y_labels, line_label, area_label, x_label)

            % Index of current data point
            k = find(LOModelData.(machine).Time == t);

            % Add all previous training data points to plot
            x = LOModelData.(machine).Load(1:k);
            y = LOModelData.(machine).Power(1:k);
            plot(x, y, 'k.', 'MarkerSize', 10)
            text(0.05, 0.95, compose("$t=%d$", t), 'Units', 'normalized', ...
                'Interpreter', 'latex')
            title(config.machines.(machine).name, 'Interpreter', 'latex')
            hLeg = findobj(gcf, 'Type', 'Legend');
            leg_labels = hLeg.String;
            legend([leg_labels(1:2) {'data'}], 'Location', 'southeast')
            if j < n_times
                set(hLeg, 'visible', 'off')
            end
        end
    
        grid on
        % Size figure appropriately
        s = get(gcf, 'Position');
        set(gcf, 'Position', [s(1:2) -30+210*n_times 210]);
        sim_name = config.simulation.name;
        filename = compose("model_preds_%.0f.pdf", t);
        save2pdf(fullfile("simulations", sim_name, "plots", filename))
    end
end
