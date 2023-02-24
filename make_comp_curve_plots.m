% Plot the load-power steady-state characteristics of 
% each compressor

addpath("plot-utils")
plot_dir = "plots";
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

% See Simulink model 'comp_curves.mdl'
out = sim("comp_curves");

include = {'C1', 'C2', 'C3', 'C4', 'C5'};
labels = compose("machine %d", 1:5);

% Plot of power consumption vs load
figure(1); clf

for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name));
    plot(x.Data, y.Data, 'linewidth', 2); hold on
    assert(endsWith(y.name, compose('machine_%d', i)))  % check labels match
end
xlabel("Compressor load (kW thermal)", 'Interpreter', 'latex')
ylabel("Power consumption (kW electric)", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
legend(escape_latex_chars(labels), ...
    'Interpreter', 'latex', 'location', 'best')
exportgraphics(gcf, "plots/comp_curves.pdf")


% Plot of specific power consumption vs load
figure(2); clf

for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name)) ./ x;
    plot(x.Data, y.Data, 'linewidth', 2); hold on
end
xlabel("Compressor load (kW thermal)", 'Interpreter', 'latex')
ylabel("Specific power consumption (kW/kW)", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
legend(escape_latex_chars(labels), ...
    'Interpreter', 'latex', 'location', 'best')
exportgraphics(gcf, "plots/comp_curves_se.pdf")