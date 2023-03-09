function [model, vars] = fp1_model_update(model, data, vars, params)
% [model, vars] = fp1_model_update(model, data, vars, params)
% Updates the first principles model to the data. This model 
% assumes that each machine has a constant efficiency 
% (defined as specific energy consumption kW/kW) which is 
% estimated by taking the average of past observations.
%

    % Specific energy estimates from observations
    specific_energy = data{:, "Power"} ./ data{:, "Load"};

    % Re-estimate the mean of the estimates from observations
    vars.specific_energy = mean(specific_energy);

    % Std. dev. of the estimates from observations
    vars.se_sigma = std(specific_energy);

    % Calculate confidence interval from observations
    intervals = [0.5.*vars.significance 1-0.5.*vars.significance];
    n = length(specific_energy);
    se = std(specific_energy) ./ sqrt(n);  % Standard Error
    ts = tinv(intervals, n - 1);  % T-Score
    vars.se_int = vars.specific_energy + ts .* se;

end