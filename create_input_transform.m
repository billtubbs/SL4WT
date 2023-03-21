function inputTransform = create_input_transform(params)
% inputTransform = create_input_transform(params)
% Creates a struct with the functions for transforming
% the inputs.
%
    inputTransform = struct();
    inputTransform.x = str2func(params.inputTransform.x);
    inputTransform.x_inv = str2func(params.inputTransform.x_inv);

end