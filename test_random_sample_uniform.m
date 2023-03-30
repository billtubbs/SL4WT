% Test random_sample_uniform.m
%

rng(0)

X = random_sample_uniform([56 220], [0.1 0.3], 3);

assert(isequal(round(X, 4), [99.1229  102.1100   76.5652]'))
