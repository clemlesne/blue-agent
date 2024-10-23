###
# Remove the Azure DevOps template agent from a pool.
#
# Usage: ./template-clean.sh <agent>
###

#!/bin/bash
set -e

agent="$1"

if [ -z "$agent" ]; then
  echo "Remove the Azure DevOps template agent from a pool."
  echo "Usage: $1 <agent>"
  exit 1
fi

pool_name="github-actions"

echo "➡️ Removing template agent ${agent} from pool ${pool_name}"

# Get the pool id
pool_id=$(az pipelines pool list \
  --pool-name "${pool_name}" \
  --query "[0].id")

# Fail if the pool does not exist
if [ -z "$pool_id" ]; then
  echo "❌ Pool ${pool_name} not found"
  exit 1
fi

# Get the agent id
agent_id=$(az pipelines agent list \
  --pool-id "${pool_id}" \
    | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"${agent}\")) and (.name | endswith(\"-template\")) and .status == \"offline\")).id // empty")

# Fail if the agent does not exist
if [ -z "$agent_id" ]; then
  echo "❌ Template agent ${agent} not found in pool ${pool_name}"
  exit 1
fi

# Remove the agent
az devops invoke \
  --api-version "7.1" \
  --area distributedtask \
  --http-method DELETE \
  --resource agents \
  --route-parameters poolId="${pool_id}" agentId="${agent_id}"

echo "✅ Agent ${agent} removed from pool ${pool_name}"
