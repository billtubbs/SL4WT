% Run simulation
%
% This script runs one complete simulation based on the 
% confugration file stored in the specified folder.
%

clear all
addpath("yaml")

% Main directory where simulation sub-directories are located
sim_dir = "simulations";

% Directory where simulation input datasets are stored
data_dir = "data";

% Choose simulation sub-directory name where config file and
% results are located
sim_name = "test_sim_gpr";  % Gaussian process models
% sim_name = "test_sim_fp1";  % Simple first-principles model
% sim_name = "test_sim_lin";  % Linear model
% sim_name = "test_sim_ens";  % Ensemble model  NOT YET WORKING, need y_sigma estimate

% Prepare sub-directories to store outputs
if ~exist(fullfile("simulations", sim_name, "results"), 'dir')
    mkdir(fullfile("simulations", sim_name, "results"))
end
if ~exist(fullfile("simulations", sim_name, "plots"), 'dir')
    mkdir(fullfile("simulations", sim_name, "plots"))
end

% Load simulation configuration from file
filepath = fullfile(sim_dir, sim_name, "sim_config.yaml");
fprintf("Loading simulation configuration from '%s'\n", filepath)
sim_config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load system configuration from file
filepath = fullfile(sim_dir, sim_name, ...
    sim_config.system.config_filename);
fprintf("Loading system configuration from '%s'\n", filepath)
sys_config = yaml.loadFile(filepath, "ConvertToArray", true);
% TODO: Setup the simulink model to load parameters from this file

% Load optimizer configuration from file
filepath = fullfile(sim_dir, sim_name, ...
    sim_config.optimizer.config_filename);
fprintf("Loading optimizer configuration from '%s'\n", filepath)
opt_config = yaml.loadFile(filepath, "ConvertToArray", true);
% Note: make sure the struct opt_config is provided to the 
% optimizer block as a parameter in the Simulink model.

% Add simulation name to optimizer config - so that optimizer
% can save data to the simulation sub-directory
opt_config.simulation.name = sim_name;

% Load simulation input data from file
filename = sim_config.simulation.inputs.filename;
load(fullfile(data_dir, filename));

% Simulink model name
sim_model = sim_config.simulation.model.filename;

% Run Simulink model simulation
fprintf("Starting simulation...\n")
t_stop = sim_config.simulation.params.t_stop;
sim_out = sim(sim_model, "StopTime", string(t_stop));
fprintf("Simulation finished.\n")
fprintf("Run 'plot_model_preds.m' to make plots of model predictions.\n")