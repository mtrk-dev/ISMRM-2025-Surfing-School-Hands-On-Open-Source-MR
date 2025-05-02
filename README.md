# ISMRM-2025-Surfing-School-Hands-On-Open-Source-MR
Materials for the ISMRM 2025 educational course "Surfing School Hands On Open Source MR" held on May 11, 2025

## Course overview

## Course sildes 

## Installing mtrk
Follow instructions on [main page](https://github.com/mtrk-dev).

## Installing KomaMRI
Follow instructions on [their repository](https://github.com/JuliaHealth/KomaMRI.jl).
Check further documentation [here](https://juliahealth.org/KomaMRI.jl/stable/).

## Generating sequences with different readouts using mtrk

## Simulating obtained sequences in KomaMRI
The previously generated sequences can be tested using KomaMRI. The images shown in the presentation were obtained using two phantoms:
* A cylinder phantom with two different compartments, supporting long TEs,
* A brain phantom reproducing the caracteristics of a human brain and giving good results on shorter TEs. 

KomaMRI's graphical user interface can be used to simulate on the bain phantom, however it does not support the cylinder phantom. 

To simulate on either the cylinder or brain phantoms and obtain the same images featured in the presentation, go to  `Simulation` and run `educational2025_mtrk_simulation.jl`. This script will ask to provide the sequence folder, the sequence name and the phantom to simulate on before performing the simulation. 
It saves results as HTML files stored in `Simulation/Results`:
* `Simulation/Results/Sequences` stores a dynamic plot of the sequence,
* `Simulation/Results/Trajectories` stores a dynamic 3D plot of the k-space readout trajectory,
* `Simulation/Results/Images` stores a plot of the reconstructed image. 
Expected results are stored in `Simulation/ExpectedResults`.
