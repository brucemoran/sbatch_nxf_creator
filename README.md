# Create SBATCH files for your Nextflow runs

## Overview
This repo was created to simplify and organise the use of Nextflow with SLURM via .sbatch files. Specifically it is of use in projects where more samples will be added, and the basic structure of those runs will be the same. It uses a YAML config that holds all information on the runs to date, and config of the Nextflow pipeline. This sounds like something Nextflow should/does do but I couldn't get it to work so made this, and the repo for ease of deployment.

NB that this was made for a specific HPC, Sonic in University College Dublin so as always YMMV.

## Usage
1) Create a base directory for your project, e.g. `mkdir /home/me/project/`.

2) Create a YAML based on the `sbatch_nxf_creator.yaml` template in this above base dir, pro-tip: prefix with a `.` to make it invisible.

3) `sh sbatch_nxf_creator.sh /home/me/project/.project.yaml` will then give rise to `/home/me/project/test_{1..2}`, each of which contain an sbatch file which will set up your working directories, and you can submit the sbatch to SLURM.

4) Possibly this sbatch will require tweaking! Fork the repo and have at it=D

## About the YAML
If you are new to YAMLs [check out this tutorial](https://www.cloudbees.com/blog/yaml-tutorial-everything-you-need-get-started)

Below are the `keys` required for the utility to work.

A key may contain an array, i.e. multiple terms denoted by a dash, but not a dictionary.

It may also be a `key-value` pair.

### NAMES
This should be a unique identifier and is used to create a directory, and tag output files.

If an array, each name is taken in turn and a directory and `sbatch` file are produced for each name.

Names can be added continuously, making this system extensible to new data coming in.

E.g. you have `test_1`, run the utility, and then add `test_2`, and run it again. This will just create the new `test_2` directory and `sbatch` file, `test_1` stays the same unless other `keys` were changed.

### PIPELINES
Here we add the `Nextflow` command. In the example `sbatch_nxf_creater.yaml`, these are tests for `sarek` and `rnaseq` nf-core workflows. This is a good way to test if the system is functional.

To add more pipelines, simply add another element.

If you want to use further pipelines, nf-core or otherwise, add them to your test `YAML`!

NB that you should retain the `{BASE_NXF}/{NAME}` structure to allow the utility to replace your output directory and working directory with what you specify in the `YAML`.

This can be extended where you want to include the `{NAME}`.

### VERS_NXF
This specifies Nextflow version for loading from `modules` (likely in a SLURM scenario). Ensure that the version you have exists!

### VERS_SNG
This specifies Singularity version as per above.

### CONF_NXF
Allows loading of your own local config file using `-c <your.config>`, leave blank if not using a local config.

### BASE_NXF
The base directory for your workflow. Must be writable!

A `.template.sbatch` file is created here which is used to generate a `.{NAME}.nextflow.config`, `.nextflow.log`, and the final `{NAME}.sbatch` files.

It is also where all output for that `{NAME}` are saved from pipeline(s), and where a `{NAME}/pipeline_info` directory records the pipeline info.
