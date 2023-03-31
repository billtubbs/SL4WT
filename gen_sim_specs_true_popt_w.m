% Generate sim specs for tuning GP models - z

addpath("yaml")

% Name of simulation and directory where sim specs and results are
sim_name = "sim_true_popt_w";

% Define directory where simulation spec files should be
sims_dir = "simulations";
sim_spec_dir = fullfile("simulations", sim_name, "sim_specs");

% Load simulation base configuration from file
sim_config_filename = "sim_spec_base.yaml";
filepath = fullfile(sim_spec_dir, sim_config_filename);
sim_config_base = yaml.loadFile(filepath, "ConvertToArray", true);

% Load optimizer base configuration from file
filepath = fullfile(sim_spec_dir, "opt_config.yaml");
opt_config_base = yaml.loadFile(filepath, "ConvertToArray", true);

% Create directory for new sim specs
if ~exist(fullfile(sim_spec_dir, "queue"), 'dir')
    mkdir(fullfile(sim_spec_dir, "queue"))
end

w_values = [0.1 1 10 100 1000 10000 100000 1e6 1e7 1e8 1e9];
n_sims = length(w_values);
for i = 1:n_sims

    % Create new sim_spec.yaml file 
    sim_config = sim_config_base;  % make a copy
    opt_config_filename = sim_config.optimizer.config_filename;
    [~, name, ext] = fileparts(opt_config_filename);
    name = compose("%s_%03d", name, i);
    new_opt_config_filename = strjoin([name ext], '');
    sim_config.optimizer.config_filename = new_opt_config_filename;

    % Save new sim_spec file in queue directory
    new_sim_spec_filename = replace(sim_config_filename, "base", ...
        compose("%02d", i));
    yaml.dumpFile(fullfile(sim_spec_dir, "queue", new_sim_spec_filename), ...
        sim_config, "block")

    % Create new opt_config.yaml file in main sim spec directory
    opt_config = opt_config_base;  % make a copy

    % Assign new parameter value and save optimizer config file
    opt_config.optimizer.params.w = w_values(i);
    yaml.dumpFile(fullfile(sim_spec_dir, new_opt_config_filename), ...
        opt_config, "block")

end