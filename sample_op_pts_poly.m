function [Y, X] = sample_op_pts_poly(X, params, sigma_M)
% [Y, X] = sample_op_pts_poly(X, params, sigma_M)
% Returns the steady-state operating point(s) of the 
% specified polynomial machine performance model given 
% the coefficients from config.
%
% Arguments:
%   X : double scalar or vector
%   params : struct
%       This must contain a row vector of coefficients:
%           params.coeff
%       and a row vector of lower and upper operating limits:
%           params.op_limits
%   sigma_M : double
%

    if nargin < 3
        sigma_M = 0;
    end

    % Clip input values to operating limits
    X = min(max(X, params.op_limits(1)), params.op_limits(2));

    % Add measurement noise
    V = sigma_M .* randn(size(X));
    Y = polyval(params.coeff, X) + V;

end