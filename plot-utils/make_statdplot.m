function ax = make_statdplot(Y_line, Y_lower, Y_upper, x, y_d, x_d, ...
    x_label, y_labels, line_label, area_label, y_lim)
% ax = make_statdplot(Y_line, Y_lower, Y_upper, x, y_d, x_d, x_label, ...
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
%   y_d : column vector of y values of data points.
%   x_d : column vector of x values of data points.
%   x_label : x-axis label (optional, default is '$x$')
%   y_labels : label or cell array of labels for each data
%     group (optional, default: '$y$').
%   line_label : string containing text to describe the 
%     mean line (optional, default: "");
%   area_label : string containing text to describe the 
%     lower and upper bounds (optional, default: "min, max");
%   y_lim : y-axis limits (optional, default is nan(2))
%
    if nargin < 11
        y_lim = nan(1, 2);
    end
    if nargin < 10
        area_label = "min, max";
    end
    if nargin < 9
        line_label = "";
    end
    ny = size(Y_line, 2);
    if nargin < 8
        if ny == 1
            y_labels = "$y(x)$";
        else
            y_labels = compose("$y_{%d}(x)$", 1:ny);
        end
    else
        y_labels = string(y_labels);
    end
    if nargin < 7
        x_label = "$x$";
    else
        x_label = string(x_label);
    end

    ax = make_statplot(Y_line, Y_lower, Y_upper, x, x_label, y_labels, ...
        line_label, area_label, y_lim);
    
    % Add data points to existing plot
    plot(x_d, y_d, 'k.', 'MarkerSize', 12)
    y_lims = [ ...
        axes_limits_with_margin([Y_upper Y_lower Y_line], 0.1, y_lim, y_lim);
        axes_limits_with_margin(y_d, 0.1, y_lim, y_lim) ...
    ];
    ylim([min(y_lims(:, 1)) max(y_lims(:, 2))])

    % Change existing legend label
    ax.Legend.String{end} = 'data';

end
