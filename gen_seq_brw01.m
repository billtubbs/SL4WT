function y = gen_seq_brw01(n, sd, y0)
% y = gen_seq_brw01(n, sd, y0)
% Generates a bounded random walk (BRW) of n samples 
% which remains approximately between 0 and 1. For 
% simplicity, BRW has pre-set parameters except sde 
% which is the std. dev. of the noise input.
%
% If y0 not given, it is sampled from a uniform
% random distribution, rand(), between 0 and 1.
%

    if nargin < 3
        % Initial value
        y0 = rand();
    end

    % Bounded random walk parameters
    beta = -15;  % note beta is k from Nicolau paper
    alpha1 = 3;
    alpha2 = 3;
    tau = 100;

    % Generate a bounded random walk (BRW) sequence
    xkm1 = tau + 5 .* (y0 - 0.5) ./ 0.5;
    phi = 0.5;
    brw = sample_bounded_random_walk(sd.*5, beta, alpha1, alpha2, ...
        n, tau, phi, xkm1);

    % Convert back to range 0-1
    y = (brw - tau) / 10 + 0.5;

end