# Create SBATCH files for your Nextflow runs

## Overview
This repo was created to simplify and organise the use of Nextflow with SLURM via `.sbatch` files. Specifically it is of use in projects where more samples will be added, and the basic structure oof those runs will be the same. It uses a YAML config that holds all information on the runs to date, and config of the Nextflow pipeline. This sounds like something Nextflow should/does do but I couldn't get it to work so made this, and the repo for ease of deployment.

## Usage
1) Create a root directory for your project, e.g. `/home/me/project/project.yaml`

2) Create a YAML based on the `sbatch_nxf_creator.yaml` template in this root dir.

3) `sh sbatch_nxf_creator.sh /home/me/project/project.yaml` will then give rise to `/home/me/project/sample_{1..4}`, each of which contain an SBATCH which will set `NXF_WORK/workDir` to `sample` dirs etc.
