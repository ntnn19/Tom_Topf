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

if [[ "$1" == "--help" ]]; then
    display_help
    exit 0
fi
# Test input validity  - colabfold weights dir

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
else
  echo "Directory '$colabfold_weights_dir' exists"
fi

# Test input validity  - config/config.yaml
# Assign the first argument to configfile
configfile="config/config.yaml"

# Check if the config file exists
if [ ! -f "$configfile" ]; then
    echo "Error: Config file '$configfile' does not exist."
    exit 1
fi

while IFS= read -r line; do
    if ! [[ "$line" =~ ^[^:]+:\ [^:]+$ ]]; then
        echo $line
        echo "Error: Each key-value pair must be on a separate line and formatted as 'key: value' with a single space after the colon."
        exit 1
    fi
done < "$configfile"

# Required key-value pairs
declare -A required_keys
required_keys=(
    ["rules_dir"]="workflow/rules"
    ["output_dir"]="workflow/results/strategy-1/hsv-1/multi,workflow/results/strategy-2/hsv-1/multi,workflow/results/strategy-3/hsv-1/multi"
    ["data_dir"]="workflow/data"
    ["scripts_dir"]="workflow/scripts"
)

# Validate that the required key-value pairs exist and have valid comma-separated values
for key in "${!required_keys[@]}"; do
    if ! grep -q -E "^$key: " "$configfile"; then
        echo "Error: Key '$key' does not exist in the config file."
        exit 1
    fi
    value=$(grep -E "^$key: " "$configfile" | cut -d':' -f2 | xargs)
    # Check if the value is a valid comma-separated string
    if [[ "$key" == "output_dir" ]]; then
        if ! [[ "$value" =~ ^[^,]+(,[^,]+)*$ ]]; then
            echo "Error: Value $value for key '$key' is not a valid comma-separated string."
            exit 1
        fi
    fi
done

# If everything is valid, parse the key-value pairs
declare -A config
while IFS=: read -r key value; do
    key=$(echo "$key" | xargs)     # Trim whitespace
    value=$(echo "$value" | xargs) # Trim whitespace
    config["$key"]="$value"
done < "$configfile"

# Print the parsed config
echo "Config file is valid."
echo "Parsing config file."
rules_dir="${config["rules_dir"]}"
output_dir="${config["output_dir"]}"
data_dir="${config["data_dir"]}"
scripts_dir="${config["scripts_dir"]}"
strategy_1_outdir=`echp $output_dir | cut -d"," -f1`

echo "Value for key 'data_dir': $data_dir"
echo "Value for key 'output_dir': $output_dir"

echo "Preparing mounting directories"
python "workflow/scripts/create_dirs.py" "config/config.yaml" $colabfold_weights_dir
if [ $# -eq 0 ]; then
    echo "Error: Creation of mounting directories failed."
    exit 1
fi
#snakemake --snakefile workflow/Snakefile  --config colabfold_weights_dir="${colabfold_weights_dir}" --use-singularity --singularity-args "--nv -B ${colabfold_weights_dir}:/cache -B $(pwd)/workflow/results/strategy-1/hsv-1/multi:/predictions" -c12 -k
echo "Executing Workflow"
snakemake --snakefile workflow/Snakefile  --config colabfold_weights_dir="${colabfold_weights_dir}" --use-singularity --singularity-args "--nv -B ${colabfold_weights_dir}:/cache -B $(pwd)/${strategy_1_outdir}:/predictions" -c12
if [ $# -eq 0 ]; then
    echo "Error: Workflow failed."
    exit 1
fi
echo "Workflow completed successfully"
