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
ENV=$(yq eval '.env' $PIPELINE_FILE)

# Store all properties from ENV, in environment variables
while IFS= read -r line; do
  # Skip empty lines
  if [ -z "$line" ]; then
    continue
  fi

  # Skip comments
  if [[ $line == \#* ]]; then
    continue
  fi

  # Split the line into key and value, based on ":"
  key=$(echo $line | cut -d':' -f1)
  value=$(echo $line | cut -d':' -f2-)

  # Trim the values
  key=$(echo $key | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  value=$(echo $value | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # Set the environment variable
  echo "From GitHub Actions: $key=$value"
  export "$key"="$value"
done <<< "$ENV"
