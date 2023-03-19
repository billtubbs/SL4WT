% test match_closest_points.m

P = [4 3 1 2]';
Q = [1 2 3 4]';
iq = match_closest_points(P, Q);
assert(isequal(iq, [3 4 2 1]'));

P = [3 1 1 2]';
Q = [1.1 2 1.2 3]';
iq = match_closest_points(P, Q);
assert(isequal(iq, [2 4 3 1]'));

rng(0)

P = [
    1 2 
    2 4 
    3 6 
    3 6
    3 6
];
Q = [
    2.9000    6.1000
    3.0000    5.9000
    1.0000    2.1000
    2.1000    4.0000
    3.1000    6.1000
];

[iq, pn] = match_closest_points(P, Q);
assert(isequal(iq, [3 4 1 2 5]'))
assert(isequal(round(pn, 7), [0.1414214 0.1 0.1 0.1 0.1414214]'))
sum_pn = sum(pn);

Q = Q(randperm(size(Q, 1)), :);
[iq, pn] = match_closest_points(P, Q);
assert(isequal(iq, [1 3 4 5 2]'))
assert(sum(pn) == sum_pn)

rng(0)
P = randn(5, 3);
Q = randn(5, 3);
[iq1, pn1] = match_closest_points(P, Q, 1);  % 1-norm
[iq2, pn2] = match_closest_points(P, Q, 2);  % 2-norm
assert(isequal(iq1, [3 1 4 5 2]'))
assert(isequal(iq2, [3 2 4 5 1]'))
assert(isequal(round(pn1, 6), ...
    [2.692042  2.838785  3.729069  2.650342  5.161385]' ...
))
assert(isequal(round(pn2, 6), ...
    [2.102913  3.124073  2.939013  1.632054  2.077931]' ...
))
sum_pn1 = sum(pn1);
sum_pn2 = sum(pn2);

% Check all permutations
i_perms = perms(1:5);
pn1_min = inf;
pn2_min = inf;
for i = 1:size(i_perms, 1)
    [iq1, pn1] = match_closest_points(P, Q(i_perms(i, :)', :), 1);
    [iq2, pn2] = match_closest_points(P, Q(i_perms(i, :)', :), 2);
    % Check sum of the sum-of-p-norms are the same
    assert(abs(sum(pn1) - sum_pn1) < 1e-14)
    assert(abs(sum(pn2) - sum_pn2) < 1e-14)
    pn1_min = min(pn1_min, sum(pn1));
    pn2_min = min(pn2_min, sum(pn2));
end
% Check the sum-of-p-norms found were the lowest
assert(abs(pn1_min - sum_pn1) < 1e-14)
assert(abs(pn2_min - sum_pn2) < 1e-14)