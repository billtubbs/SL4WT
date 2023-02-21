% Run simulation

clear all
addpath("yaml")

% Simulink model name
sim_model = "multiple_generators_els_2021b.mdl";

% Main folder where simulations and results are located
sim_dir = "simulations";

% Choose simulation sub-directory name where config file
% is located
%sim_name = "test_sim";
sim_name = "test_sim_fp1";

% Prepare sub-directories to store outputs
if ~exist(fullfile("simulations", sim_name, "plots"), 'dir')
    mkdir(fullfile("simulations", sim_name, "plots"))
end
if ~exist(fullfile("simulations", sim_name, "results"), 'dir')
    mkdir(fullfile("simulations", sim_name, "results"))
end

% Load configuration file
filepath = fullfile(sim_dir, sim_name, "opt_config.yaml");
fprintf("Loading optimizer configuration from '%s'\n", filepath)
config = yaml.loadFile(filepath, "ConvertToArray", true);

% Over-write name just to make sure it matches folder
config.simulation.name = sim_name;

fprintf("Starting simulation...\n")
t_stop = config.simulation.params.t_stop;
sim_out = sim(sim_model, "StopTime", string(t_stop));
fprintf("Simulation finished.\n")
fprintf("Run 'plot_model_preds.m' to make plots of model predictions.\n")