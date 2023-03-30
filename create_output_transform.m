function outputTransform = create_output_transform(params)
% outputTransform = create_output_transform(params)
% Creates a struct with the functions for transforming
% the outputs.
%
    outputTransform = struct();
    outputTransform.y = str2func(params.outputTransform.y);
    outputTransform.y_sigma = str2func(params.outputTransform.y_sigma);
    outputTransform.y_inv = str2func(params.outputTransform.y_inv);

end