% Run a test simulation
%
% Note: This fails when run as a 'runtests' unit test
% Have to run it seperately.
%

clear all
addpath("yaml")

% Main directory where simulation sub-directories are
sims_dir = "tests/simulations";

% Sim name
sim_name = "test_sim";

% Directory where config files are stored
sim_spec_dir = fullfile(sims_dir, sim_name, "sim_specs");
if ~exist(sim_spec_dir, 'dir')
    error(compose("Directory '%s' not found", sim_spec_dir))
end

% If there is no queue sub-directory, the script will look in 
% sim_spec_dir for a sim spec file with the following name 
sim_spec_filename = "sim_spec.yaml";

% Directory where simulation input datasets are stored
data_dir = "data";

% Prepare sub-directories to store outputs
results_dir = fullfile(sims_dir, sim_name, "results");
if ~exist(results_dir, 'dir')
    mkdir(results_dir)
end
plot_dir = fullfile(sims_dir, sim_name, "plots");
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

% Load simulation configuration from file
filepath = fullfile(sim_spec_dir, sim_spec_filename);
sim_config = yaml.loadFile(filepath, "ConvertToArray", true);

% Initialize random number generator if seed specified
if isfield(sim_config.simulation.params, "seed")
    rng(sim_config.simulation.params.seed)
end

% Load system configuration from file
filepath = fullfile(sim_spec_dir, sim_config.system.config_filename);
sys_config = yaml.loadFile(filepath, "ConvertToArray", true);

% Load optimizer configuration from file
filepath = fullfile(sim_spec_dir, sim_config.optimizer.config_filename);
opt_config = yaml.loadFile(filepath, "ConvertToArray", true);

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