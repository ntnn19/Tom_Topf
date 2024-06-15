#!/bin/bash
python "workflow/scripts/create_dirs.py" "config/config.yaml"
snakemake --snakefile workflow/Snakefile -c4