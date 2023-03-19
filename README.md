# SL4WT

MATLAB scripts to run real-time optimization (RTO) simulation experiments.

The plant model is a Simulink model of a refrigeration system with 5 parallel compressors, developed by Mehmet Mercangöz, 
Imperial College, 2023.


## Usage

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

Following this, you may run the script [plot_model_preds.m](plot_model_preds.m) to make a plot figure of the fitted models.

Plot figures are saved to a sub-directory called 'plots' within the simulation sub-directory.

The 'sim_name' varuable refers to a sub-directory in the 'simulations' directory which contains a config file that defines the 
simulation and load optimizer setup.

The outputs of the simulation are written to a sub-directory called 'results' in the simulation sub-directory.

For multiple simulations, a simulation summary file named 'sims_summary.csv' is appended to by each simulation this contains most of the parameter settings and configuration of each simulation, plus the evaluation metrics.

Evaluation metrics include:
```lang-none
         OriginalVariableNames          Sim_1      Sim_2      Sim_3      Sim_4      Sim_5     Sim_6      Sim_7      Sim_8  
    _______________________________    _______    _______    _______    _______    _______    ______    _______    ________

    {'final_model_RMSE'           }    0.45504    0.42763    0.65127    0.27842    0.12858    0.1129    0.10555    0.085272
    {'max_power_limit_exceedance' }          0          0          0          0          0         0          0      237.13
    {'mean_excess_power_used'     }     5.4602     3.9934     7.1262     6.0541     9.1856    16.017     20.345       23.84
    {'mean_excess_power_used_pct' }    0.38199    0.27965    0.49794    0.42331    0.64119    1.1133     1.4143      1.6398
    {'mean_load_losses_vs_target' }     97.895     97.877     97.559     97.491     98.483    99.273      107.3       84.37
    {'mean_power_limit_exceedance'}          0          0          0          0          0         0          0      13.949
    {'total_model_uncertainty'    }     601.58      565.7      524.1     465.47     432.82    358.01     391.51      395.68

```

## Other files

Simulink model file:
 - [multiple_generators_els_2021b.mdl](multiple_generators_els_2021b.mdl)

Other scripts:
 - [evaluate_models.m](evaluate_models.m) - runs Monte Carlo experiments to evaluate the extrapolation behaviour of each 
   model type when trained on small samples of random training points
 - [find_optimum_solution.m](find_optimum_solution.m) - runs repeated optimizations to determine the optimum load balancing 
   solution at a range of target loads
 - [make_comp_curve_plots.m](make_comp_curve_plots.m) - makes plots showing the power vs. load characteristics of each compressor
 - [match_closest_points.m](match_closest_points.m) - function script to match the load and power values of a set of machines to an existing set of load and power values.
 
 
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
