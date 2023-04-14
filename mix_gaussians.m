function [mu, ci, sigma] = mix_gaussians(mus, sigmas, alpha)

    n_dists = length(mus);
    assert(length(sigmas) == n_dists);

    % Calculate 99.5% confidence intervals in std. devs.
    sd = norminv(0.5 + 0.995 / 2);

    % Decide on the x-range to generate particles over
    x_mins = mus - sigmas .* sd;
    x_maxes = mus + sigmas .* sd;
    n_p = 501;  % number of bins
    x = linspace(min(x_mins), max(x_maxes), n_p);
    dx = diff(x(1:2));
    particles = nan(n_dists, n_p);
    for i = 1:n_dists
        particles(i, :) = normpdf(x, mus(i), sigmas(i));
    end

    % Could fit a normal distribution to the data
    %pd = fitdist(x,'Normal')

    mixed_pdf = mean(particles);
    %mixed_pdf = mixed_pdf ./ sum(mixed_pdf .* dx);
    mixed_cdf = cumsum(mixed_pdf .* dx);
    % correct errors in cdf (assuming equal probability missed
    % at lower and upper ends)
    mixed_cdf = mixed_cdf + 0.5*(1 - mixed_cdf(end));
    % Estimate median (not used)
    %median = interp1(mixed_cdf, x, 0.5);
    % Estimate lower and upper confidence intervals
    ci = interp1(mixed_cdf, x, [alpha 1-alpha]);

    % Estimate mean
    mu = sum(x .* mixed_pdf ./ sum(mixed_pdf));

    % Estimate std. dev. of equivalent normal distribution
    sigma1 = diff(interp1(mixed_cdf, x, [0.158655 0.841345])) / 2;
    sigma2 = diff(interp1(mixed_cdf, x, [0.022750 0.977250])) / 4;
    sigma3 = diff(interp1(mixed_cdf, x, [0.001350 0.998650])) / 6;
    sigma = mean([sigma1 sigma2 sigma3], 'omitnan');

%     figure(1); clf;
%     x_lower = x < ci(1);
%     x_upper = x > ci(2);
%     plot(x, mixed_pdf); hold on
%     area(x(x_lower), mixed_pdf(x_lower), 'FaceColor','r');
%     area(x(x_upper), mixed_pdf(x_upper), 'FaceColor','r');
%     plot(x, normpdf(x, mu, sigma)); 
%     xline(mu, '--');
%     grid on
%     legend(["mixture" "lower" "upper" "normal" "mean"])

end