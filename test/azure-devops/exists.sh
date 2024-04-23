###
# Test the existence of an Azure DevOps agent in a pool.
#
# If the agent is found, the script will exit with status 0. Will retry every 5 seconds, indefinitely, until the agent is found.
#
# Usage: ./exists.sh <agent>
###

#!/bin/bash
set -e

agent="$1"

if [ -z "$agent" ]; then
  echo "Test the existence of an Azure DevOps agent in a pool."
  echo "Usage: $1 <agent>"
  exit 1
fi

pool_name="github-actions"

echo "Testing existence of agent ${agent} in pool ${pool_name}"

# Get the pool id
pool_id=$(az pipelines pool list \
  --pool-name "${pool_name}" \
  --query "[0].id")

if [ -z "$pool_id" ]; then
  echo "Pool ${pool_name} not found"
  exit 1
fi

while true; do
  agent_json=$(az pipelines agent list \
    --pool-id "${pool_id}" \
      | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"${agent}\")) and .status == \"online\"))")
  if [ -n "$agent_json" ] && [ "$agent_json" != "null" ]; then
    break
  fi
  echo "Agent ${agent} not found in pool ${pool_name} (${pool_id}), retrying in 5 seconds"
  sleep 5
done

agent_name=$(echo "${agent_json}" | jq -r ".name")
agent_id=$(echo "${agent_json}" | jq -r ".id")

echo "✅ Agent ${agent_name} (${agent_id}) found in pool ${pool_name} (${pool_id})"

agent_capabilities=$(az pipelines agent show \
  --agent-id "${agent_id}" \
  --include-capabilities \
  --pool-id "${pool_id}" \
    | jq -r ".systemCapabilities")

echo "Capabilities:"
echo ${agent_capabilities} | jq -r "to_entries | map(\"\(.key)=\(.value | tostring)\") | sort[]"
