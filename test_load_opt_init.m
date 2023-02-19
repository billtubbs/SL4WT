% Test initialization file is correct (no data)

clear variables

ws = load("load_opt_init.mat");

assert(isequal( ...
    fieldnames(ws), ...
    {'LOData', 'LOModelData', 'curr_iteration', 'model_vars', ...
     'models'}' ...
))
assert(ws.curr_iteration == 0)
assert(isempty(fieldnames(ws.LOData)))
assert(isempty(fieldnames(ws.LOModelData)))
assert(isempty(fieldnames(ws.models)))
assert(isempty(fieldnames(ws.model_vars)))