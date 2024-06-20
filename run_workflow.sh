#!/bin/bash

# Function to display help message
display_help() {
    echo "Usage: $0 [OPTIONS] colabfold_weights_dir"
    echo
    echo "Options:"
    echo "  help             Display this help message and exit."
    echo
    echo "Arguments:"
    echo "  colabfold_weights_dir  Path to the ColabFold weights directory."
    echo
    echo "Example:"
    echo "  $0 /path/to/colabfold/weights"
}

# Check if arguments are provided
if [ $# -eq 0 ]; then
    echo "Error: No arguments provided."
    display_help
    exit 1
fi

# Handle the "help" argument
if [ "$1" == "help" ]; then
    display_help
    exit 0
fi

# Validate the colabfold_weights_dir argument
colabfold_weights_dir=$1

if [ -z "$colabfold_weights_dir" ]; then
    echo "Error: colabfold_weights_dir is not specified."
    display_help
    exit 1
fi

if [ -e "$colabfold_weights_dir" ] && [ ! -d "$colabfold_weights_dir" ]; then
    echo "Error: '$colabfold_weights_dir' exists but is not a directory."
    exit 1
fi

# Create the directory if it does not exist
if [ ! -e "$colabfold_weights_dir" ]; then
    echo "Directory '$colabfold_weights_dir' does not exist. Creating it..."
fi

python "workflow/scripts/create_dirs.py" "config/config.yaml" $colabfold_weights_dir

snakemake --snakefile workflow/Snakefile  --config colabfold_weights_dir="${colabfold_weights_dir}" --use-singularity --singularity-args "--nv -B ${colabfold_weights_dir}:/cache -B $(pwd)/workflow/results/strategy-1/hsv-1/multi:/predictions" -c12 -k
