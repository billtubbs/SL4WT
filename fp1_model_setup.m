function [model, vars] = fp1_model_setup(data, params)
% [model, vars] = fp1_model_setup(data, params)
% Fits a first principles model to data. This model assumes
% that each machine has a constant efficiency (defined as
% specific energy consumption kW/kW) which is estimated by 
% taking the average of past observations.
%

    model = struct();  % no model object needed for this
    vars = struct("significance", params.significance);

    if ~isempty(data{:, params.predictorNames})

        % Estimate specific energy from the data provided
        [model, vars] = fp1_model_update([], data, vars, params);

        % If there is only one data point then need to use 
        % the prior values to estimate confidence interval
        % and std. dev.
        if length(data.Load) == 1
            vars.se_int = ( ...
                (params.prior.se_int - params.prior.specific_energy) ...
                    .* vars.specific_energy ...
                    ./ params.prior.specific_energy ...
                + vars.specific_energy ...
            );
            vars.se_sigma = params.prior.se_sigma;
        end

    else

        % If no data provided, set variables to prior values
        vars.specific_energy = params.prior.specific_energy;
        vars.se_sigma = params.prior.se_sigma;
        vars.se_int = params.prior.se_int;

    end

end