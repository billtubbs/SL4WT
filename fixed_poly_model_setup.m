function [model, vars] = fixed_poly_model_setup(data, params)
% [model, vars] = fixed_poly_model_setup(data, params)
% Initialises a fixed model based on a specified 
% polynomial function of the form:
%
%   y = a + b * x + c * x^2 + ... 
%

    % Since this is a fixed model, no fitting is reuired
    % and any data provided is ignored

    % Check coefficient values have been provided
    assert(~isempty(params.coeff));
    assert(all(~isnan(params.coeff)));

    % Empty vars and model objects
    vars = struct;
    model = struct;

end