function make_statdplot(Y_line, Y_lower, Y_upper, x, y_d, x_d, x_label, ...
    y_labels, line_label, area_label, y_lim)
% make_statplot(Y_line, Y_lower, Y_upper, x, y_d, x_d, x_label, ...
%     y_labels, line_label, area_label, y_lim)
% Plots a curve of the mean, lower and upper bound of a 
% variable y = f(x) and a set of data points.
%
% Arguments
%   Y_line : column vector or array of mean (or median) 
%     values to be plotted as solid lines.
%   Y_lower : column vector or array definining the lower
%     bound(s) of an area to be filled.
%   Y_upper : column vector or array definining the upper
%     bound(s) of an area to be filled.
%   x : column vector of x values.
%   y_labels : label or cell array of labels for each data
%     group (optional, default: '$y$').
%   line_label : string containing text to describe the 
%     mean line (optional, default: "");
%   area_label : string containing text to describe the 
%     lower and upper bounds (optional, default: "min, max");
%   x_label : x-axis label (optional, default is '$x$')
%   y_lim : y-axis limits (optional, default is nan(2))
%
    if nargin < 11
        y_lim = nan(2);
    end
    if nargin < 10
        area_label = "min, max";
    end
    if nargin < 9
        line_label = "";
    end
    ny = size(Y_line, 2);
    if nargin < 8
        if n == 1
            y_labels = "$y(t)$";
        else
            y_labels = compose("$y_{%d}(t)$", 1:ny);
        end
    else
        y_labels = string(y_labels);
    end
    if nargin < 7
        x_label = "$x$";
    else
        x_label = string(x_label);
    end
    line_labels = cell(1, numel(y_labels)*2);
    % Get color order
    colors = get(gca,'colororder');
    set(gca, 'ColorOrder', colors);
    for iy = 1:ny
        line_labels{iy*2-1} = strcat(y_labels(iy), " ", area_label);
        line_labels{iy*2} = strcat(y_labels(iy), " ", line_label);
        % Modify colors if plotting more than one group
        if numel(Y_line) > 1
            colors = get(gca,'colororder');
        end
        % Make filled area plot
        inBetween = [Y_lower(:,iy); flip(Y_upper(:,iy))];
        x2 = [x; flip(x)];
        fill(x2, inBetween, colors(iy, :), 'LineStyle', 'none'); 
        alpha(.25); hold on
        % Add line plot
        h = plot(x, Y_line(:,iy), 'Linewidth', 2);
        %set(h, {'color'}, {colors(1, :); colors(2, :)});
        set(h, {'color'}, {colors(iy, :)});
    end
    % Add data points to plot
    plot(x_d, y_d, 'k.', 'MarkerSize', 10)
    y_lims = [ ...
        axes_limits_with_margin([Y_upper Y_lower], 0.1, y_lim, y_lim);
        axes_limits_with_margin(y_d, 0.1, y_lim, y_lim) ...
    ];
    ylim([min(y_lims(:, 1)) max(y_lims(:, 2))])
    set(gca, 'TickLabelInterpreter', 'latex')
    if strlength(x_label) > 0
        xlabel(x_label, 'Interpreter', 'Latex')
    end
    ylabel(strjoin(y_labels, ', '), 'Interpreter', 'latex')
    legend([line_labels "data"], 'Interpreter', 'latex', 'Location', 'best')
    grid on
