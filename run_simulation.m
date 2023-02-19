% Run simulation

clear variables
addpath("yaml")

% Simulink model name
sim_model = "multiple_generators_els_2021b.mdl";

% Main folder where simulations and results are located
sim_dir = "simulations";

% Choose simulation sub-directory name where config file
% is located
sim_name = "test_sim";

% Load optimizer configuration file
filepath = fullfile(sim_dir, sim_name, "opt_config.yaml");
fprintf("Loading optimizer configuration from '%s'\n", filepath)
opt_config = yaml.loadFile(filepath, "ConvertToArray", true);

fprintf("Starting simulation...\n")
t_stop = opt_config.simulation.params.t_stop;
sim_out = sim(sim_model, "StopTime", string(t_stop));
fprintf("Simulation finished.\n")
