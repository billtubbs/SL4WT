% Run simulation
%
% This script runs one complete simulation based on the 
% confugration file stored in the specified folder.
%

clear all
addpath("yaml")

% Main folder where simulation sub-directories are located
sim_dir = "simulations";

% Choose simulation sub-directory name where config file and
% results are located
sim_name = "test_sim_gpr";  % Gaussian process models
%sim_name = "test_sim_fp1";  % Simple first-principles model
%sim_name = "test_sim_lin";  % Linear model
%sim_name = "test_sim_ens";  % Ensemble model

% Prepare sub-directories to store outputs
if ~exist(fullfile("simulations", sim_name, "results"), 'dir')
    mkdir(fullfile("simulations", sim_name, "results"))
end
if ~exist(fullfile("simulations", sim_name, "plots"), 'dir')
    mkdir(fullfile("simulations", sim_name, "plots"))
end

% Load optimizer configuration from file
filepath = fullfile(sim_dir, sim_name, "opt_config.yaml");
fprintf("Loading optimizer configuration from '%s'\n", filepath)
opt_config = yaml.loadFile(filepath, "ConvertToArray", true);
% Note: make sure the struct opt_config is provided to the 
% optimizer block as a parameter in the Simulink model.

% Simulink model name
sim_model = opt_config.simulation.model.filename;

% Add simulation name to otpimizer config - so that optimizer
% can save data to the simulations directory
opt_config.simulation.name = sim_name;

% Run Simulink model simulation
fprintf("Starting simulation...\n")
t_stop = opt_config.simulation.params.t_stop;
sim_out = sim(sim_model, "StopTime", string(t_stop));
fprintf("Simulation finished.\n")
fprintf("Run 'plot_model_preds.m' to make plots of model predictions.\n")