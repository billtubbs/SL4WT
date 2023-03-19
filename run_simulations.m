% Run simulation
%
% This script runs a set of simulations defined by the
% configuration file(s) stored in the specified folder.
%

clear all
addpath("yaml")

% Main directory where simulation sub-directories are
sims_dir = "simulations";

% Choose simulation sub-directory name where config files, data,
% are located and results will be stored
% sim_name = "test_sim_gpr";  % Gaussian process models
% sim_name = "test_sim_fp1";  % Simple first-principles model
% sim_name = "test_sim_lin";  % Linear model
% TODO: For some reason the linear model simulation is very slow
% sim_name = "test_sim_ens";  % Ensemble model  NOT YET WORKING, need y_sigma estimate
% sim_name = "test_sim_true";  % test optimizer with true system model
% sim_name = "test_sim_multiple";
sim_name = "sim_gpr_popt";

% Directory where config files are stored
sim_spec_dir = fullfile(sims_dir, sim_name, "sim_specs");
if ~exist(sim_spec_dir, 'dir')
    error(compose("Directory '%s' not found", sim_spec_dir))
end

% If there is no queue sub-directory, the script will look in 
% sim_spec_dir for a sim spec file with the following name 
sim_spec_filename = "sim_spec.yaml";

% Check if there is a queue directory containing config files
filepath = fullfile(sim_spec_dir, "queue");
if exist(filepath, 'dir')
    file_pattern = "*.yaml";
    files_info = dir(fullfile(filepath, file_pattern));
    n_sim_queue = length(files_info);

    % Process all files in those folders.
    if n_sim_queue == 0
        fprintf("No sim spec files found in queue folder:\n%s\n", filepath)
    else
        fprintf("\nStarting multiple simulations...\n")
        fprintf("%16s: %d\n", "No. of files found", n_sim_queue)
    end

    % Make a directory to save completed sim spec files
    if ~isfolder(fullfile(sim_spec_dir, 'done'))
        mkdir(fullfile(sim_spec_dir, 'done'))
    end

else

    n_sim_queue = 0;
    fprintf("\nStarting single simulation...\n")

end

% Directory where simulation input datasets are stored
data_dir = "data";
if ~exist(data_dir, 'dir')
    error(compose("Directory '%s' not found", data_dir))
end

% Prepare sub-directories to store outputs
results_dir = fullfile(sims_dir, sim_name, "results");
if ~exist(results_dir, 'dir')
    mkdir(results_dir)
end
plot_dir = fullfile(sims_dir, sim_name, "plots");
if ~exist(plot_dir, 'dir')
    mkdir(plot_dir)
end

start_time = datetime();
fprintf("%16s: %s\n", "Start time", string(start_time,"HH:mm:ss"))
i_sim = 0;
while true

    % If there are sim spec files remaining in the queue 
    % directory, copy the next one to the main sim_spec_dir.

    if n_sim_queue > 0
        i_sim = i_sim + 1;
        % Move sim spec file from queue to sim_spec_dir
        move_from = fullfile(files_info(i_sim).folder, files_info(i_sim).name);
        move_to = fullfile(sim_spec_dir, sim_spec_filename);
        movefile(move_from, move_to)
        fprintf("\nSimulation %d of %d\n", i_sim, n_sim_queue)
    end

    % Run simulation catching any errors
    to_folder = "done";
    try
        run_sim_spec
    catch ME
        fprintf("Simulation failed due to the following error:\n")
        disp(getReport(ME))
        if n_sim_queue > 0
            % If multiple simulations, move failed sim spec
            % to separate directory.
            to_folder = "failed";
        end
    end

    % Move completed sim_spec file to 'done' directory
    if n_sim_queue > 0
        move_from = fullfile(sim_spec_dir, sim_spec_filename);
        move_to = fullfile(sim_spec_dir, to_folder, files_info(i_sim).name);
        if ~exist(to_folder, 'dir')
            mkdir(to_folder)
        end
        movefile(move_from, move_to)
    end

    if i_sim >= n_sim_queue
        break
    end

end
end_time = datetime();
fprintf("%16s: %s\n", "End time", string(end_time,"HH:mm:ss"))
fprintf("%16s: %s\n", "Duration", string(end_time - start_time))