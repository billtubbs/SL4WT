% Plot the load-power steady-state characteristics of 
% each compressor

addpath("plot-utils")

% See Simulink model 'comp_curves.mdl'
out = sim("comp_curves");

include = {'C1', 'C2', 'C3', 'C4', 'C5'};
labels = cell(1, numel(include));

figure(1); clf

for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name));
    plot(x.Data, y.Data, 'linewidth', 2); hold on
    labels{i} = y.name;
end
xlabel("Compressor load", 'Interpreter', 'latex')
ylabel("Power consumption", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
legend(escape_latex_chars(labels), ...
    'Interpreter', 'latex', 'location', 'best')

mkdir("plots")
exportgraphics(gcf, "plots/comp_curves.pdf")
