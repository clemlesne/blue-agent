###
# Remove the Azure DevOps template agent from a pool.
#
# Usage: ./template-clean.sh <agent>
###

#!/bin/bash
set -e

agent="$1"
pool_id="$2"

if [ -z "$agent" ] || [ -z "$pool_id" ]; then
  echo "Remove the Azure DevOps template agent from a pool."
  echo "Usage: $1 <agent> $2 <pool_id>"
  exit 1
fi

echo "➡️ Removing template agent $agent from pool $pool_id"

# Get the agent id
agent_id=$(az pipelines agent list \
  --pool-id "$pool_id" \
    | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"$agent\")) and (.name | endswith(\"-template\")) and .status == \"offline\")).id // empty")

# Fail if the agent does not exist
if [ -z "$agent_id" ]; then
  echo "❌ Template agent not found"
  exit 1
fi
echo "Agent id: ${agent_id}"

# Remove the agent
az devops invoke \
  --api-version "7.1" \
  --area distributedtask \
  --http-method DELETE \
  --resource agents \
  --route-parameters poolId="$pool_id" agentId="$agent_id"

echo "✅ Agent removed"
