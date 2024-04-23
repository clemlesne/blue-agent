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

org_url="https://dev.azure.com/blue-agent"

echo "Configuring Azure DevOps organization ${org_url}"
az devops configure --defaults organization=${org_url}

bash test/azure-devops/exists.sh "${agent}"

# Run all integration tests in parallel
pids=""
for test in $(basename -s .yaml test/pipeline/*.yaml); do
  bash test/azure-devops/pipeline.sh "${prefix}" "${test}" "${flavor}" "${version}" &
  pids="$pids $!"
done

# Wait for all background jobs to complete
for pid in $pids; do
  wait $pid || let "RESULT=1"
done

# Exit if any of them failed
if [ "$RESULT" == "1" ]; then
  echo "One or more integration tests failed"
  exit 1
fi

bash test/azure-devops/has-been-cleaned.sh "${agent}"
