#!/bin/bash
set -e

agent="$1"
pool_id="$2"

if [ -z "$agent" ] || [ -z "$pool_id" ]; then
  echo "Test is an Azure DevOps has been cleaned up from a pool."
  echo "Usage: $1 <agent> $2 <pool_id>"
  exit 1
fi

echo "➡️ Testing existence of agent $agent in pool $pool_id"

# Wait for the agent ot be removed, as it is cleaned up asynchronously
# TODO: Add a discriminator to the agent properties, like an environment variable, to ensure there is no test collision when running multiple tests in parallel from the same branch.
echo "⏳ Waiting for the agent ot be removed"
while true; do
  agent_name=$(az pipelines agent list \
    --pool-id "$pool_id" \
      | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"$agent\")) and (.name | endswith(\"-template\") | not) and .status == \"offline\")).name // empty")
  if [ -z "$agent_name" ]; then
    echo "✅ Agent has been cleaned"
    break
  fi
  echo "Agent still exists, retrying in 5 seconds"
  sleep 5
done
