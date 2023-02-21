function [model, vars] = fp1_model_setup(data, params)
% [model, vars] = fp1_model_setup(data, params)
% Fits a first principles model to data. This model assumes
% that each machine has a constant efficiency (defined as
% specific energy consumption kW/kW) which is estimated by 
% taking the average of past observations.
%

    model = struct();  % no model object needed for this

    if size(data.Load, 1) > 0

        % Estimate specific energy from the data provided
        vars = struct("significance", params.prior.significance);
        [model, vars] = fp1_model_update([], data, vars, params);

        % If there is only one data point then need to 
        % use the prior value of the confidence interval
        % shifted to the mean of the data.
        if size(data.Load, 1) == 1
            vars.se_int = ( ...
                (params.prior.se_int - params.prior.specific_energy) ...
                    .* vars.specific_energy ...
                    ./ params.prior.specific_energy ...
                + vars.specific_energy ...
            );
        end

    else

        % If no data provided, set variables to prior values
        vars = struct( ...
            "y_sigma", params.prior.y_sigma, ...
            "specific_energy", params.prior.specific_energy, ...
            "se_int", params.prior.se_int, ...
            "significance", params.prior.significance ...
        );

    end

end