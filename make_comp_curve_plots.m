% Plot the load-power steady-state characteristics of 
% each compressor - for figures in published paper

clear

addpath("plot-utils")
plot_dir = "plots";
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

% See Simulink model 'comp_curves.mdl'
out = sim("comp_curves");

include = {'C1', 'C2', 'C3'};
labels = {'machine 1', 'machine 2', 'machines 3-5'};


%% Plot of power consumption vs load
figure(1); clf

% Extract data for plots
for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name));
    plot(x.Data, y.Data, 'linewidth', 1); hold on
    assert(endsWith(y.name, compose('machine_%d', i)))  % check labels match
end
xlabel("Cooling load (kW)", 'Interpreter', 'latex')
ylabel("Power consumption (kW electric)", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
legend(escape_latex_chars(labels), ...
    'Interpreter', 'latex', 'location', 'best')

% Resize
%p = get(gcf, 'Position');
figsize = [3.5 3];
set(gcf, 'Units', 'inches', ...
    'Position', [3 4, figsize], ...
    'PaperUnits', 'inches', ...
    'PaperSize', figsize ...
)

filename = "comp_curves_power_3-5in.pdf";
save2pdf(fullfile(plot_dir, filename))
% exportgraphics(gcf, fullfile(plot_dir, filename))


%% Plot of coefficient of performance (COP) vs load
figure(2); clf

% Extract data for plots
for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name));
    plot(x.Data, x.Data ./ y.Data, 'linewidth', 1); hold on
end
ylim(axes_limits_with_margin(x.Data ./ y.Data))
xlabel("Cooling load (kW)", 'Interpreter', 'latex')
ylabel("COP", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
legend(escape_latex_chars(labels), ...
    'Interpreter', 'latex', 'location', 'best')

% Resize
%p = get(gcf, 'Position');
figsize = [3.5 3];
set(gcf, 'Units', 'inches', ...
    'Position', [6.5 4, figsize], ...
    'PaperUnits', 'inches', ...
    'PaperSize', figsize ...
)

filename = "comp_curves_cop_3-5in.pdf";
save2pdf(fullfile(plot_dir, filename))
%exportgraphics(gcf, fullfile(plot_dir, filename))


%% Both plots combined - with COP
figure(3); clf

tiledlayout(2,1);

nexttile
for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name));
    plot(x.Data, y.Data, 'linewidth', 1); hold on
    assert(endsWith(y.name, compose('machine_%d', i)))  % check labels match
end
%xlabel("Cooling load (kW)", 'Interpreter', 'latex')
ylabel("Power (kW)", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
legend(escape_latex_chars(labels), ...
    'Interpreter', 'latex', 'location', 'best')
title("(a) Power consumption", 'Interpreter', 'latex')
%annotation('rectangle', [0 0 1 1], 'Color', 'w');

nexttile
for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name));
    plot(x.Data, x.Data ./ y.Data, 'linewidth', 1); hold on
end
ylim(axes_limits_with_margin(x.Data ./ y.Data))  % the biggest is last
xlabel("Cooling load (kW)", 'Interpreter', 'latex')
ylabel("Load / power", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
%legend(escape_latex_chars(labels), ...
%    'Interpreter', 'latex', 'location', 'best')
%annotation('rectangle', [0 0 1 1], 'Color', 'w');
title("(b) Coefficient of performance (COP)", 'Interpreter', 'latex')

% Resize
%p = get(gcf, 'Position');
figsize = [3.5 4];
set(gcf, 'Units', 'inches', ...
    'Position', [10 4, figsize], ...
    'PaperUnits', 'inches', ...
    'PaperSize', figsize ...
)

filename = "comp_curves_pow_cop_3-5in.pdf";
save2pdf(fullfile(plot_dir, filename))
%exportgraphics(gcf, fullfile(plot_dir, filename))


%% Both plots combined - with Specific Power
figure(4); clf

tiledlayout(2,1);

nexttile
for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name));
    plot(x.Data, y.Data, 'linewidth', 1); hold on
    assert(endsWith(y.name, compose('machine_%d', i)))  % check labels match
end
%xlabel("Cooling load (kW)", 'Interpreter', 'latex')
ylabel("Power (kW)", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
legend(escape_latex_chars(labels), ...
    'Interpreter', 'latex', 'location', 'best')
title("(a) Power consumption", 'Interpreter', 'latex')
%annotation('rectangle', [0 0 1 1], 'Color', 'w');

nexttile
for i = 1:numel(include)
    name = include{i};
    x = out.(compose("%s_LOAD", name));
    y = out.(compose("%s_POW", name));
    plot(x.Data, y.Data ./ x.Data , 'linewidth', 1); hold on
end
ylim(axes_limits_with_margin(y.Data ./ x.Data))  % the biggest is last
xlabel("Cooling load (kW)", 'Interpreter', 'latex')
ylabel("Power / load", 'Interpreter', 'latex')
grid on
set(gca, 'TickLabelInterpreter', 'latex')
%legend(escape_latex_chars(labels), ...
%    'Interpreter', 'latex', 'location', 'best')
%annotation('rectangle', [0 0 1 1], 'Color', 'w');
title("(b) Specific power", 'Interpreter', 'latex')

% Resize
%p = get(gcf, 'Position');
figsize = [3.5 4];
set(gcf, 'Units', 'inches', ...
    'Position', [13.5 4, figsize], ...
    'PaperUnits', 'inches', ...
    'PaperSize', figsize ...
)

filename = "comp_curves_pow_sp_3-5in.pdf";
save2pdf(fullfile(plot_dir, filename))
%exportgraphics(gcf, fullfile(plot_dir, filename))