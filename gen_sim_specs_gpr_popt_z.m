% Generate sim specs for tuning GP models - z

addpath("yaml")

% Name of simulation and directory where sim specs and results are
sim_name = "sim_gpr_popt_z";

% Base optimizer config file to use
opt_config_filenames = [
    "opt_config_lin.yaml"  % unfitted prior
    "opt_config_gpr1.yaml"  % defaults
    "opt_config_gpr2.yaml"  % fitted linear basis func
    "opt_config_gpr3.yaml"  % unfitted prior
];

% Define directory where simulation spec files should be
sims_dir = "simulations";
sim_spec_dir = fullfile("simulations", sim_name, "sim_specs");

% Load simulation base configuration from file
sim_config_filename = "sim_spec_base.yaml";
filepath = fullfile(sim_spec_dir, sim_config_filename);
sim_config_base = yaml.loadFile(filepath, "ConvertToArray", true);

% Create directory for new sim specs
if ~exist(fullfile(sim_spec_dir, "queue"), 'dir')
    mkdir(fullfile(sim_spec_dir, "queue"))
end

z_values = [10 100 1000 10000 100000 1e6 1e7 1e8 1e9 1e10 1e11 1e12];
n_z_values = length(z_values);

n_opt = length(opt_config_filenames);
for i = 1:n_opt
    opt_config_filename = opt_config_filenames(i);

    % Load optimizer base configuration from file
    filepath = fullfile(sim_spec_dir, opt_config_filename);
    opt_config_base = yaml.loadFile(filepath, "ConvertToArray", true);

    % Check params set correctly
    assert(isequal( ...
        opt_config_base.optimizer.params, ...
        struct( ...
            "n_searches", 10, ...
                     "w", 1000, ...
                     "z", 10000, ...
                  "PMax", 1580 ...
        ) ...
    ))
    assert(strcmp(opt_config_base.optimizer.obj_func, ...
        "LoadObjFun"))
    assert(strcmp(opt_config_base.optimizer.const_func, ...
        "MaxPowerConstraint"))

    for j = 1:n_z_values
    
        % Create new sim_spec.yaml file 
        sim_config = sim_config_base;  % make a copy
        % Change opt config filename
        sim_config.optimizer.config_filename = opt_config_filename;
        [~, name, ext] = fileparts(opt_config_filename);
        name = compose("%s_%02d", name, j);
        new_opt_config_filename = strjoin([name ext], '');
        sim_config.optimizer.config_filename = new_opt_config_filename;
    
        % Save new sim_spec file in queue directory
        new_sim_spec_filename = replace(sim_config_filename, "base", ...
            compose("%d_%02d", i, j));
        yaml.dumpFile(fullfile(sim_spec_dir, "queue", new_sim_spec_filename), ...
            sim_config, "block")
    
        % Create new opt_config.yaml file in main sim spec directory
        opt_config = opt_config_base;  % make a copy
    
        % Assign new parameter value and save optimizer config file
        opt_config.optimizer.params.z = z_values(j);
        yaml.dumpFile(fullfile(sim_spec_dir, new_opt_config_filename), ...
            opt_config, "block")
    
        fprintf("sim_spec file '%s' created\n", new_sim_spec_filename)
        fprintf("opt_config file '%s' created\n", new_opt_config_filename)
    
    end
end