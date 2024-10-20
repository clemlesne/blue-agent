#!/bin/bash
set -e

agent="$1"

if [ -z "$agent" ]; then
  echo "Test is an Azure DevOps has been cleaned up from a pool."
  echo "Usage: $1 <agent>"
  exit 1
fi

pool_name="github-actions"

echo "➡️ Testing existence of agent ${agent} in pool ${pool_name}"

# Get the pool id
pool_id=$(az pipelines pool list \
  --pool-name "${pool_name}" \
  --query "[0].id")

if [ -z "$pool_id" ]; then
  echo "Pool ${pool_name} not found"
  exit 1
fi

# TODO: Add a discriminator to the agent properties, like an environment variable, to ensure there is no test collision when running multiple tests in parallel from the same branch.
# Wait for the agent ot be removed, as it is cleaned up asynchronously
for i in {1..12}; do
  agent_name=$(az pipelines agent list \
    --pool-id "${pool_id}" \
      | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"${agent}\")) and .status == \"offline\")).name")
  if [ -n "$agent_name" ] && [ "$agent_name" != "null" ]; then
    echo "Agent ${agent_name} exists, retrying in 5 seconds"
    sleep 5
  else
    echo "✅ Agent ${agent} has been cleaned from pool ${pool_name} (${pool_id})"
    exit 0
  fi
done

echo "❌ Agent ${agent} has not been cleaned from pool ${pool_name} (${pool_id})"
exit 1
