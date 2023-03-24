function [iq, pn] = match_closest_points(P, Q, p)
% [iq, pn] = match_closest_points(P, Q, p)
% Returns a column vector of indices of the rows
% in matrix P which, if used to sort matrix Q, would 
% result in the values in the rows in Q most-closely 
% matching those of the rows in P. By default (p = 2),
% the sum of the distances between the points is 
% minimized (i.e. the 2-norm). For the 1-norm use
% p = 1.
%
% Note:
%   - this function is only designed for matching
%     in low dimensions - no more than 10 rows in P
%     and Q.
%
% Example:
% >> P = [1 2 3 4]';
% >> Q = [2.1 1.1 3.9 3.2]';
% >> iq = match_closest_points(P, Q) 
% 
% iq_match =
% 
%      2
%      1
%      4
%      3
%
% >> Q(iq, :)
% 
% ans =
% 
%     1.1000
%     2.1000
%     3.2000
%     3.9000
%

    if nargin < 3
        p = 2;
    end
    n = size(P, 1);
    assert(size(Q, 1) == n)
    assert(n <= 10, "too many permuations")
    i_perms = perms(1:n);
    np = size(i_perms, 1);
    d_min = inf;
    p_norms = cell(1, np);
    for i = 1:np
        iq = i_perms(i, :);
        d = nan(n, 1);
        % Note: could use pagenorm introduced in version R2022b
        for j = 1:n
            d(j) = norm(P(iq(j), :) - Q(j, :), p);  % p-norm
        end
        p_norms{i} = d;
        d_sum = sum(d);
        if d_sum <= d_min
            d_min = d_sum;
            i_min = i;
        end
    end
    iq = i_perms(i_min, :)';
    pn = p_norms{i_min};

end