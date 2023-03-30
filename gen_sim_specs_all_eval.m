% Generate sim specs for running evaluation simulations
% on selected optimizers and all input sequences.
%
% After running this you can start all the simulations 
% by editing run_simulations.m and setting sim_name 
% and then running it.
%

clear all

addpath("yaml")


% Select optimizers (optimizer config filenames)
opt_config_filenames = [
    "opt_config_gpr1.yaml" ...
    "opt_config_gpr2.yaml" ...
    "opt_config_gpr3.yaml" ...
    "opt_config_lin.yaml" ...
    "opt_config_true.yaml" ...
];

% Select input seqs
i_seqs = 1:22;

% Name of simulation and directory where sim specs and results are
sim_name = "sim_all_eval";

% Define directory where simulation spec files should be
sims_dir = "simulations";
sim_spec_dir = fullfile("simulations", sim_name, "sim_specs");

% Create directories if they don't exist
if ~exist(sim_spec_dir, 'dir')
    mkdir(sim_spec_dir)
end
if ~exist(fullfile(sim_spec_dir, "queue"), 'dir')
    mkdir(fullfile(sim_spec_dir, "queue"))
end

% Load simulation base configuration from file
sim_spec_filename = "sim_spec_base.yaml";
filepath = fullfile(sim_spec_dir, sim_spec_filename);
sim_spec_base = yaml.loadFile(filepath, "ConvertToArray", true);

for i_opt = 1:length(opt_config_filenames)

    for i_seq = i_seqs

        % Create new sim_spec.yaml file
        sim_spec = sim_spec_base;  % make a copy
    
        % Load optimizer base configuration from file
        opt_config_filename = opt_config_filenames(i_opt);
        filepath = fullfile(sim_spec_dir, opt_config_filename);
        opt_config = yaml.loadFile(filepath, "ConvertToArray", true);
    
        % Check key params are the same
        if isfield(opt_config.optimizer.params, "w")
            assert(opt_config.optimizer.params.w == 1000)
        end
        if isfield(opt_config.optimizer.params, "z")
            assert(opt_config.optimizer.params.z == 10000)
        end
        if isfield(opt_config.models.model_1.params, "significance")
            assert(opt_config.models.model_1.params.significance == 0.1)
            assert(opt_config.models.model_2.params.significance == 0.1)
            assert(opt_config.models.model_3.params.significance == 0.1)
        end
        assert(strcmp(opt_config.optimizer.obj_func, ...
            "LoadObjFun"))
        assert(strcmp(opt_config.optimizer.const_func, ...
            "MaxPowerConstraint"))
    
        % Change opt config filename in sim spec
        sim_spec.optimizer.config_filename = opt_config_filename;
    
        % Change input sequence filename
        sim_spec.simulation.inputs.filename = ...
            sprintf("load_sequence_%02d.mat", i_seq);

        % Change initial training data for models
        machine_names = string(fieldnames(opt_config.machines));
        n_machines = length(machine_names);
        for m = 1:n_machines
            machine = machine_names(m);
            new_td_filename = sprintf("machine_%d_data_%02d.csv", m, i_seq);
            opt_config.machines.(machine).trainingData = ...
                new_td_filename;
        end

        % Save new opt_config file in sim_spec directory
        [~, name, ext] = fileparts(opt_config_filename);
        name = compose("%s_%d_%03d", name, i_opt, i_seq);
        new_opt_config_filename = strjoin([name ext], '');
        yaml.dumpFile(fullfile(sim_spec_dir, new_opt_config_filename), ...
            opt_config, "block")

        % Change input sequence filename
        sim_spec.optimizer.config_filename = new_opt_config_filename;

        % Save new sim_spec file in queue directory
        [~, name, ext] = fileparts(sim_spec_filename);
        name = compose("%s_%d_%03d", name, i_opt, i_seq);
        new_sim_spec_filename = strjoin([name ext], '');
        yaml.dumpFile(fullfile(sim_spec_dir, "queue", new_sim_spec_filename), ...
            sim_spec, "block")
    
        fprintf("sim_spec file '%s' created\n", new_sim_spec_filename)

    end

end