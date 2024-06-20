#!/bin/bash
#modify to accept user args:  colabfold weights dir
colabfold_weights_dir=$1
python "workflow/scripts/create_dirs.py" "config/config.yaml" $colabfold_weights_dir

snakemake --snakefile workflow/Snakefile  --config muscle-params="${colabfold_weights_dir}" --use-singularity --singularity-args "--nv -B ${colabfold_weights_dir}:/cache -B $(pwd)/workflow/results/strategy-1/hsv-1/multi:/predictions" -c12 -k
