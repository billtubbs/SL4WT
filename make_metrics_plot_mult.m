function axs = make_metrics_plot_mult(metrics_summaries, labels)
% axs = make_metrics_plot_mult(metrics_summary)
%
% metrics_summary is a cell array containing a set of metrics_summary
% tables produced by sim_save_outputs.m See plot_model_preds_mult.m.
%

    t = metrics_summaries{1}.t;
    n_sims = length(metrics_summaries);

    line_style = '.-';
    marker_size = 12;

    tcl = tiledlayout(4, 1);
    axs = gobjects(4, 1);

    axs(1) = nexttile(tcl);
    y_values = cell(1, n_sims);
    for i = 1:n_sims
        y_values{i} = metrics_summaries{i}.power_limit_exceedances;
        plot(t, y_values{i}, line_style, 'Linewidth', 1, ...
            'MarkerSize', marker_size); hold on
    end
    ylim(axes_limits_with_margin(cell2mat(y_values), 0.1, [0 10]))
    set(gca, 'TickLabelInterpreter', 'latex')
    ylabel('Metric', 'Interpreter', 'latex')
    title("(a) Power limit exceedances (kW)", 'Interpreter', 'latex')
    grid on

    axs(2) = nexttile(tcl);
    for i = 1:n_sims
        y_values{i} = metrics_summaries{i}.load_tracking_errors_vs_max;
        plot(t, y_values{i}, line_style, 'Linewidth', 1, ...
            'MarkerSize', marker_size); hold on
    end
    ylim(axes_limits_with_margin(cell2mat(y_values), 0.1, [0 10]))
    set(gca, 'TickLabelInterpreter', 'latex')
    ylabel('Metric', 'Interpreter', 'latex')
    title("(b) Load tracking errors (kW)", 'Interpreter', 'latex')
    grid on

    axs(3) = nexttile(tcl);
    for i = 1:n_sims
        y_values{i} = metrics_summaries{i}.excess_power_used;
        plot(t, y_values{i}, line_style, 'Linewidth', 1, ...
            'MarkerSize', marker_size); hold on
    end
    ylim(axes_limits_with_margin(cell2mat(y_values), 0.1, [0 10]))
    set(gca, 'TickLabelInterpreter', 'latex')
    ylabel('Metric', 'Interpreter', 'latex')
    title("(c) Excess power used (kW)", 'Interpreter', 'latex')
    grid on

    axs(4) = nexttile(tcl);
    for i = 1:n_sims
        y_values{i} = metrics_summaries{i}.overall_model_RMSE;
        plot(t, y_values{i}, line_style, 'Linewidth', 1, ...
            'MarkerSize', marker_size); hold on
    end
    ylim(axes_limits_with_margin(cell2mat(y_values), 0.1, [0 10]))
    set(gca, 'TickLabelInterpreter', 'latex')
    xlabel('Time (s)', 'Interpreter', 'latex')
    ylabel('Metric', 'Interpreter', 'latex')
    title("(d) Overall model error (RMSE)", 'Interpreter', 'latex')
    grid on

    linkaxes(axs, 'x')

    % Create a legend below the figure
    hL = legend(labels, 'Interpreter', 'latex', 'Orientation', 'horizontal');
    hL.Location = 'southoutside';
    %hL.Layout.Tile = 'South';

    % Resize plot and save as pdf
    set(gcf, 'Units', 'inches');
    p = get(gcf, 'Position');
    figsize = [3.5 5];
    set(gcf, ...
        'Position', [p(1:2) figsize] ...
    )

end