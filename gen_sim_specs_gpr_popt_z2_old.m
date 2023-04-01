% Generate sim specs for tuning GP models - z

addpath("yaml")

% Name of simulation and directory where sim specs and results are
sim_name = "sim_gpr_popt_z2";

% Base optimizer config file to use
%opt_config_filename = "opt_config_gpr1.yaml";
opt_config_filename = "opt_config_gpr2.yaml";

% Define directory where simulation spec files should be
sims_dir = "simulations";
sim_spec_dir = fullfile("simulations", sim_name, "sim_specs");

% Load simulation base configuration from file
sim_config_filename = "sim_spec_base.yaml";
filepath = fullfile(sim_spec_dir, sim_config_filename);
sim_config_base = yaml.loadFile(filepath, "ConvertToArray", true);

% Load optimizer base configuration from file
filepath = fullfile(sim_spec_dir, opt_config_filename);
opt_config_base = yaml.loadFile(filepath, "ConvertToArray", true);

% Create directory for new sim specs
if ~exist(fullfile(sim_spec_dir, "queue"), 'dir')
    mkdir(fullfile(sim_spec_dir, "queue"))
end

z_values = [1e-3 0.01 0.1 1 10 100 1000 1e4 1e5 1e6];
n_sims = length(z_values);
for i = 1:n_sims

    % Create new sim_spec.yaml file 
    sim_config = sim_config_base;  % make a copy
    % Change opt config filename
    sim_config.optimizer.config_filename = opt_config_filename;
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
    opt_config.optimizer.params.z = z_values(i);
    yaml.dumpFile(fullfile(sim_spec_dir, new_opt_config_filename), ...
        opt_config, "block")

    fprintf("sim_spec file '%s' created\n", new_sim_spec_filename)
    fprintf("opt_config file '%s' created\n", new_opt_config_filename)

end