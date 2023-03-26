% Sets up and runs one simulation experiment based on
% the settings specified in the Yaml file in the
% specified simulation directory. 
%
% This file is called by run_simulations.m and various
% variables should exist in the workspace when it is called.
% Therefore, there should not be no 'clear variables' command
% in this file.
% 
% The reason this task cannot be set up a function is that
% you need to run a simulink model with all the variables in
% the base workspace.
%

% Load simulation configuration from file
filepath = fullfile(sim_spec_dir, sim_spec_filename);
fprintf("Loading simulation configuration from '%s'\n", filepath)
sim_config = yaml.loadFile(filepath, "ConvertToArray", true);

% Initialize random number generator if seed specified
if isfield(sim_config.simulation.params, "seed")
    rng(sim_config.simulation.params.seed)
end

% Load system configuration from file
filepath = fullfile(sim_spec_dir, sim_config.system.config_filename);
fprintf("Loading system configuration from '%s'\n", filepath)
sys_config = yaml.loadFile(filepath, "ConvertToArray", true);
% TODO: Setup the simulink model to load parameters from this file

% Load optimizer configuration from file
filepath = fullfile(sim_spec_dir, sim_config.optimizer.config_filename);
fprintf("Loading optimizer configuration from '%s'\n", filepath)
opt_config = yaml.loadFile(filepath, "ConvertToArray", true);
% Note: make sure the struct opt_config is provided to the 
% optimizer block as a parameter in the Simulink model.

% Add simulation directory names to optimizer config - so that 
% optimizer can save data to the simulation sub-directory
opt_config.simulation.sims_dir = sims_dir;
opt_config.simulation.name = sim_name;

% Load simulation input data from file
filename = sim_config.simulation.inputs.filename;
load(fullfile(data_dir, filename), "inputs");

% Simulink model name
sim_model = sim_config.simulation.model.filename;

% Run Simulink model simulation
fprintf("Starting simulation...\n")
t_stop = sim_config.simulation.params.t_stop;
sim_out = sim(sim_model, "StopTime", string(t_stop));
fprintf("Simulation finished.\n")

% Save simulation results
filename = "sim_out.mat";
filepath = fullfile(results_dir, filename);
save(filepath, "sim_out")
fprintf("Simulation results saved to '%s'.\n", filepath)

% Run script to calculate performance metrics and save results
output_script_name = sim_config.simulation.outputs.save_script;
run(output_script_name)

% Run script to make plots (if selected)
if isfield(sim_config.simulation.outputs, "plot_script")
    run(sim_config.simulation.outputs.plot_script)
else
    % Announcement
    fprintf("Run 'plot_model_preds' to make plots.\n")
end

