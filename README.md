# SL4WT

MATLAB scripts to run real-time optimization (RTO) simulation experiments.

The plant model is a Simulink model of a refrigeration system with 5 parallel compressors, developed by Mehmet Mercangöz, 
Imperial College, 2023.


## Usage

Open the script [run_simulation.m](run_simulation.m).

In the top part of this script you can choose which simulation to run:
```lang-matlab
% Choose simulation sub-directory name where config file and
% results are located
sim_name = "test_sim_gpr";  % Gaussian process models
%sim_name = "test_sim_fp1";  % Simple first-principles model
%sim_name = "test_sim_lin";  % Linear model
%sim_name = "test_sim_ens";  % Ensemble model
```

Following this, you may run the script [plot_model_preds.m](plot_model_preds.m) to make a plot figure of the fitted models.
The plots are saved to a sub-directory called 'plots' within the simulation sub-directory.

The 'sim_name' varuable refers to a sub-directory in the 'simulations' directory which contains a config file that defines the 
simulation and load optimizer setup.

The outputs of the simulation are written to a sub-directory called 'results' in the simulation sub-directory.


## Other files

Simulink model file:
 - [multiple_generators_els_2021b.mdl](multiple_generators_els_2021b.mdl)

Other scripts:
 - [evaluate_models.m](evaluate_models.m) - runs Monte Carlo experiments to evaluate the extrapolation behaviour of each 
   model type when trained on small samples of random training points
 - [find_optimum_solution.m](find_optimum_solution.m) - runs repeated optimizations to determine the optimum load balancing 
   solution at a range of target loads
 - [make_comp_curve_plots.m](make_comp_curve_plots.m) - makes plots showing the power vs. load characteristics of each compressor
 
 
## Unit testing
 
To run the unit tests, execute the following command in the main directory from MATLAB.
```lang-matlab
runtests
```

## References

 - Cheng (2023). Generate Random Points in Multi-Dimensional Space subject to Linear Constraints 
   (https://www.mathworks.com/matlabcentral/fileexchange/36070-generate-random-points-in-multi-dimensional-space-subject-to-linear-constraints), 
   MATLAB Central File Exchange. Retrieved February 27, 2023.
 - Martin Koch (2023). yaml (https://github.com/MartinKoch123/yaml/releases/tag/v1.5.3), GitHub. Retrieved February 28, 2023.
