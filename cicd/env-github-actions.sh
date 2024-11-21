#!/usr/bin/bash

# Define the path to the pipeline file
PIPELINE_FILE=".github/workflows/pipeline.yaml"

# Check if yq is installed
if ! command -v yq &> /dev/null
then
  echo "yq could not be found, please install it to proceed."
  exit 1
fi

# Check if the pipeline file exists
if [ ! -f "$PIPELINE_FILE" ]; then
  echo "Pipeline file does not exist: $PIPELINE_FILE"
  exit 1
fi

# Get "env" property from pipeline file
ENV=$(yq '.env | to_entries | map("\(.key)=\(.value)") | .[]' $PIPELINE_FILE)

# Store all properties from ENV, in environment variables
while IFS= read -r line; do
  # Remove double quotes
  line=$(echo $line | sed 's/\"//g')
  # Set the environment variable
  echo "From GitHub Actions: $line"
  export "$line"
done <<< "$ENV"
