% Transforming output predictions

rng(0)


%% Output transformation 1 - COP
y0 = 1.4;  % avg. COP

% Transformation
f = @(x, y) x ./ (y + y0);

% Std. deviation
sigma = 0.1;
random_samples = sigma .* randn(10000, 1);

figure(1)
subplot(2, 1, 1)
histogram(random_samples);
grid on

x0 = 100;
random_samples2 = f(x0, random_samples);

subplot(2, 1, 2)
histogram(random_samples2);
grid on

fprintf("Skewness: %g\n", skewness(random_samples2))


%% Output transformation 2 - specific power
y0 = 0.7;

% Transformation
f2 = @(x, y) (y + y0) .* x;

% Std. deviation
sigma = 0.1;
random_samples = sigma .* randn(10000, 1);

figure(2)
subplot(2, 1, 1)
histogram(random_samples);
grid on

x0 = 100;
random_samples2 = f2(x0, random_samples);

subplot(2, 1, 2)
histogram(random_samples2);
grid on

fprintf("Skewness: %g\n", skewness(random_samples2))


