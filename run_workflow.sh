#!/bin/bash
python "workflow/scripts/create_dirs.py" "config/config.yaml"
snakemake --snakefile workflow/Snakefile  --use-singularity --singularity-args "--nv -B /home/nnagar/singularity_containers/colabfold/weights:/cache -B $(pwd)/workflow/results:/predictions" -n