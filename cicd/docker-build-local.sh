#!/usr/bin/bash

# Load the environment variables
source cicd/env-github-actions.sh

# Folder and prefix for all Dockerfiles
FOLDER="src/docker"
PREFIX="${FOLDER}/Dockerfile-"

# Initialize the SUFFIXES variable
SUFFIXES="$1"

# Check if docker is installed
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed, please install it to proceed."
  exit
fi

# Check if the SUFFIXES variable is empty
if [ -z "$SUFFIXES" ]; then
  echo "No suffixes provided, building all Docker images."

  # Iterate over files with the pattern "Dockerfile-*"
  for file in $PREFIX*; do
    # Extract the suffix from the file name
    suffix="${file#$PREFIX}"
    # Append the suffix to the SUFFIXES variable
    SUFFIXES="${SUFFIXES} ${suffix}"
  done
fi

# Print the SUFFIXES variable
echo "Matrix:${SUFFIXES}"

# Iterate over the suffixes and build the Docker images
for suffix in ${SUFFIXES}; do
  tag="ghcr.io/clemlesne/azure-pipelines-agent:${suffix}-latest"
  echo "➡️ Building Docker image for ${suffix} (${tag})"

  # Build the Docker image
  DOCKER_BUILDKIT=1 docker build \
    --build-arg "AWS_CLI_VERSION=${AWS_CLI_VERSION}" \
    --build-arg "AZP_AGENT_VERSION=${AZP_AGENT_VERSION}" \
    --build-arg "AZURE_CLI_VERSION=${AZURE_CLI_VERSION}" \
    --build-arg "BUILDKIT_VERSION=${BUILDKIT_VERSION}" \
    --build-arg "GCLOUD_CLI_VERSION=${GCLOUD_CLI_VERSION}" \
    --build-arg "GIT_VERSION=${GIT_WIN_VERSION}" \
    --build-arg "GO_VERSION=${GO_VERSION}" \
    --build-arg "JQ_VERSION=${JQ_VERSION}" \
    --build-arg "POWERSHELL_VERSION=${POWERSHELL_VERSION}" \
    --build-arg "PYTHON_VERSION=${PYTHON_WIN_VERSION}" \
    --build-arg "ROOTLESSKIT_VERSION=${ROOTLESSKIT_VERSION}" \
    --build-arg "TINI_VERSION=${TINI_VERSION}" \
    --build-arg "VS_BUILDTOOLS_VERSION=${VS_BUILDTOOLS_WIN_VERSION}" \
    --build-arg "YQ_VERSION=${YQ_VERSION}" \
    --build-arg "ZSTD_VERSION=${ZSTD_WIN_VERSION}" \
    --tag $tag \
    --file ${PREFIX}${suffix} \
    $FOLDER
done
