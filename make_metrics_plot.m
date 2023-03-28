function axs = make_metrics_plot(metrics_summary)
% axs = make_metrics_plot(metrics_summary)
%
% metrics_summary is a table produced by sim_save_outputs.m
% and should be in the workspace immediately after running
% run_simulations.m.  Alternatively, it can be loaded as 
% follows, for example:
%
% >> sim_name = "test_sim_true";
% >> filename = sprintf("%s_metrics.csv", sim_name);
% >> results_dir = sprintf("simulations/%s/results", sim_name);
% >> metrics_summary = readtable(fullfile(results_dir, filename));
%

    t = metrics_summary.t;

    line_style = '.-';
    marker_size = 12;

    axs = repmat(axes, 4, 1);

    axs(1) = subplot(4,1,1);
    y_values = metrics_summary.power_limit_exceedances;
    plot(t, y_values, line_style, 'Linewidth', 2, ...
        'MarkerSize', marker_size);
    ylim(axes_limits_with_margin(y_values, 0.1, [0 10]))
    set(gca, 'TickLabelInterpreter', 'latex')
    ylabel('Metric', 'Interpreter', 'latex')
    title("(a) Power limit exceedances (kW)", 'Interpreter', 'latex')
    grid on

    axs(2) = subplot(4,1,2);
    y_values = metrics_summary.load_shortfalls_vs_max;
    plot(t, y_values, line_style, 'Linewidth', 2, ...
        'MarkerSize', marker_size);
    ylim(axes_limits_with_margin(y_values, 0.1, [0 10]))
    set(gca, 'TickLabelInterpreter', 'latex')
    ylabel('Metric', 'Interpreter', 'latex')
    title("(b) Load shortfalls (kW)", 'Interpreter', 'latex')
    grid on

    axs(3) = subplot(4,1,3);
    y_values = metrics_summary.excess_power_used;
    plot(t, y_values, line_style, 'Linewidth', 2, ...
        'MarkerSize', marker_size);
    ylim(axes_limits_with_margin(y_values, 0.1, [0 10]))
    set(gca, 'TickLabelInterpreter', 'latex')
    ylabel('Metric', 'Interpreter', 'latex')
    title("(c) Excess power used (kW)", 'Interpreter', 'latex')
    grid on

    axs(4) = subplot(4,1,4);
    y_values = metrics_summary.overall_model_RMSE;
    plot(t, y_values, line_style, 'Linewidth', 2, ...
        'MarkerSize', marker_size);
    ylim(axes_limits_with_margin(y_values, 0.1, [0 10]))
    set(gca, 'TickLabelInterpreter', 'latex')
    xlabel('Time (s)', 'Interpreter', 'latex')
    ylabel('Metric', 'Interpreter', 'latex')
    title("(d) Overall model error (RMSE)", 'Interpreter', 'latex')
    grid on

    linkaxes(axs, 'x')

    % Resize plot and save as pdf
    set(gcf, 'Units', 'inches');
    p = get(gcf, 'Position');
    figsize = [3.5 4];
    set(gcf, ...
        'Position', [p(1:2) figsize] ...
    )

end