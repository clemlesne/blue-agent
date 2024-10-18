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

# Create .env if it does not exist
if [ ! -f ".env" ]; then
  touch .env
fi

# Get "env" property from pipeline file
ENV=$(yq '.env' $PIPELINE_FILE)

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

  # If there is no ":" in the line, skip it
  if [[ $line != *":"* ]]; then
    continue
  fi

  # Split the line into key and value, based on ":"
  key=$(echo $line | cut -d':' -f1 | sed 's/^"//;s/"$//')
  value=$(echo $line | cut -d':' -f2- | sed 's/^"//;s/"$//')

  # Trim the values
  key=$(echo $key | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  value=$(echo $value | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # Trim double quotes
  key=$(echo $key | sed 's/^"//;s/"$//')
  value=$(echo $value | sed 's/^"//;s/"$//')

  # Set the environment variable
  echo "From GitHub Actions: $key=$value"
  export "$key"="$value"
done <<< "$ENV"
