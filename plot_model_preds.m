% Plots model predictions for last simulation
%
% Make sure that sim_name is set to the name of the simulation
%
%  - n_machines
%  - sim_name
%


filename = compose("%s_%s_preds_%.0f.csv", sim_name, machine, t);
model_preds = readtable(fullfile("simulations", sim_name, ...
                "results", filename));

figure(1); clf
y_labels = "Power";
line_label = "predicted";
area_label = "confidence interval";
x_label = "Load";

for i = 1:n_machines
    % Plot predictions and training data points
    subplot(1, n_machines, i);
    make_statplot(y_means{i}, y_int{i}(:, 1), y_int{i}(:, 2), ...
        op_interval, y_labels, line_label, area_label, x_label)
    h = findobj(gcf, 'Type', 'Legend');
    leg_labels = h.String;
    % Add training data points to plot
    plot(LOModelData.(machine).Load, LOModelData.(machine).Power, ...
        'k.', 'MarkerSize', 10)
    legend([leg_labels 'data'], 'Location', 'southeast')
    text(0.05, 0.95, compose("$t=%d$", t), 'Units', 'normalized', ...
        'Interpreter', 'latex')
    title(compose("Machine %d", i), 'Interpreter', 'latex')
end

grid on
% Size figure appropriately
s = get(gcf, 'Position');
set(gcf, 'Position', [s(1:2) 420+280*n_machines 280]);
sim_name = config.simulation.name;
filename = compose("model_preds_%.0f.pdf", t);
exportgraphics(gcf, fullfile("simulations", sim_name, "plots", filename))
disp('Stop')
