# SL4WT

MATLAB scripts to evaluate the Adaptive Real Time Exploration and Optimization (ARTEO) algorithm using a simulated refrigeration plant.

The refrigeration plant is simulated in Simulink. It has 5 parallel compressors, as shown in the diagram below.

<IMG SRC="https://user-images.githubusercontent.com/7958850/228906717-c947f887-9147-4ffa-b941-5ee489dfb47f.png" WIDTH="50%">

The model was developed by Mehmet Mercangöz and coworkers at Imperial College, London, based on work by K. N. Widell, and T. Eikevik (2010) at 
Norwegian University of Science and Technology.

This work is part of a research project supervised by Dr. Mercangöz.  The results here have been submitted as a conference paper proposal (not yet accepted) with the following title:
 - Using Prior Knowledge to Improve Adaptive Real Time Exploration and Optimization

## To reproduce the results in the paper

After downloading the code, I recommend running the unittests first (MATLAB command line from the main repository directory):
```lang-matlab
runtests
```

Note: There are two tests which may fail. [test_run_simulation.m](test_run_simulation.m) always fails when executed by `runtests` because it runs a Simulink model. To do this test, open the script and run it the normal way (not as a unit test) in MATLAB. The [test_ens_model.m](test_ens_model.m) fails because this model has not been implemented yet.

Then, you need to generate the random simulation inputs:
```lang-matlab
gen_input_seqs
```

Then, run this script to compute the optimal machine loads for all machines (warning: This takes about 15 minutes):
```lang-matlab
find_optimum_solution
```
(Once this script has finished, the optimum load solutions are saved on file so it shouldn't need to be run again).

Open the script [run_simulations.m](run_simulations.m).

In the top part of this script you can choose from a set of test simulations to run:
```lang-matlab
% Choose simulation sub-directory name where config files, data,
% are located and results will be stored
% sim_name = "test_sim_gpr";  % Gaussian process models
% sim_name = "test_sim_fp1";  % Simple first-principles model
% sim_name = "test_sim_lin";  % Linear model
sim_name = "test_sim_true";  % test optimizer with true system models
```

The 'sim_name' variable refers to a sub-directory in the 'simulations' directory which contains a config file that defines the 
simulation and load optimizer setup.

Evaluation metrics for each simulation include:
```lang-none
Max. power limit exceedance: 0 kW
Avg. power limit exceedance: 0 kW
Avg. load tracking errors vs. target: 1 kW
Avg. load tracking errors vs. max.: 1 kW
Avg. excess power used: 3.992 kW
Avg. excess power used: 0.3% (of total)
Final total model uncertainty: 2.5
Final overall model prediction error (RMSE): 2.0 kW
Number of times optimizer failed: 0
```

After running [run_simulations.m](run_simulations.m), you may run [plot_model_preds.m](plot_model_preds.m) to make various plots of the simulation results and the fitted models.

Plot figures are saved to a sub-directory called 'plots' within the simulation sub-directory.

The outputs of the simulation are written to a sub-directory called 'results' in the simulation sub-directory.

Details of every simulation (configuration, optimizer parameters, evaluation results etc.) are appended to a summary file named 'sims_summary.csv'. Note that this file is not over-written, so it is useful for accumulating and comparing results from multiple simulations. To delete past simulation results, just delete all files in the results sub-folder of the simulation directory.

If everything appears to be working, you can try running the main evaluation simulations. Warning: There are 110 simulations which take about 5 hours to complete.

Once complete, you can run the following script to produce the box-plot shown in the paper:
```lang-matlab
analyse_results_all_eval.m
```


## Other files

Simulink model file:
 - [multiple_generators_els_2021b.mdl](multiple_generators_els_2021b.mdl)

Other scripts:
 - [evaluate_models.m](evaluate_models.m) - runs Monte Carlo experiments to evaluate the extrapolation behaviour of each 
   model type when trained on small samples of random training points
 - [make_comp_curve_plots.m](make_comp_curve_plots.m) - makes plots showing the power vs. load characteristics of each compressor
 
Functions:
 - [match_closest_points.m](match_closest_points.m) - function script to match the load and power values of a set of machines to an existing set of load and power values.

Utility functions:
 - [yaml](yaml) - this directory contains a package by Martin Koch (2023) for reading and writing Yaml files
 - [data-utils](data-utils) - various data processing tools
 - [plot-utils](data-utils) - various plotting tools

## Unit testing
 
To run the unit tests, execute the following command in the main directory from MATLAB.
```lang-matlab
runtests
```

## References

 - Buse Sibel Korkmaz, Marta Zagórowska, Mehmet Mercangöz (2022), Safe Optimization of an Industrial Refrigeration Process Using an Adaptive and Explorative Framework, arXiv preprint arXiv:2211.13019, (https://arxiv.org/abs/2211.13019)
 - Cheng (2023). Generate Random Points in Multi-Dimensional Space subject to Linear Constraints 
   (https://www.mathworks.com/matlabcentral/fileexchange/36070-generate-random-points-in-multi-dimensional-space-subject-to-linear-constraints), 
   MATLAB Central File Exchange. Retrieved February 27, 2023.
 - Martin Koch (2023). yaml (https://github.com/MartinKoch123/yaml/releases/tag/v1.5.3), GitHub. Retrieved February 28, 2023.
