#!/bin/bash
set -e

prefix="$1"
flavor="$2"
version="$3"
agent="$4"

if [ -z "$prefix" ] || [ -z "$flavor" ] || [ -z "$version" ] || [ -z "$agent" ]; then
  echo "Run all integration tests cases."
  echo "Usage: $1 <prefix> $2 <flavor> $3 <version> $4 <agent>"
  exit 1
fi

echo "➡️ Running integration tests for agent ${agent} with prefix ${prefix}, flavor ${flavor} and version ${version}"

org_url="https://dev.azure.com/blue-agent"
echo "Configuring Azure DevOps organization ${org_url}"
az devops configure --defaults organization=${org_url}

# Test if template exists
bash test/azure-devops/template-exists.sh "${agent}"

# Run all integration tests in parallel
parallel -j 0 bash test/azure-devops/pipeline.sh "${prefix}" {} "${flavor}" "${version}" ::: $(basename -s .yaml test/pipeline/*.yaml)

# Check if any of the tests failed
if [ $? -ne 0 ]; then
  echo "❌ One or more integration tests failed"
  exit 1
fi

# Test if all jobs were cleaned automatically
bash test/azure-devops/queue-cleaned.sh "${agent}"
