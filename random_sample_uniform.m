function X = random_sample_uniform(op_limits, sample_range, n)
% X = random_sample_uniform(op_limits, sample_range, n)
%
% Generates n random samples from a uniform distribution
% between a subs-set of the full operating range of a
% machine.
%
% Example
% >> X = random_sample_uniform([56 220], [0.1 0.3], 3)
%
% X =
% 
%    99.1229
%   102.1100
%    76.5652
% 

    X = op_limits(1) + (sample_range(1) ...
        + rand(1, n)' .* diff(sample_range)) .* diff(op_limits);

end