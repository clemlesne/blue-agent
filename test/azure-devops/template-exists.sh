###
# Test the existence of a Azure DevOps template agent in a pool.
#
# If the agent is found, the script will exit with status 0. Will retry every 5 seconds, indefinitely, until the agent is found.
#
# Usage: ./template-exists.sh <agent>
###

#!/bin/bash
set -e

agent="$1"

if [ -z "$agent" ]; then
  echo "Test the existence of a Azure DevOps template agent in a pool."
  echo "Usage: $1 <agent>"
  exit 1
fi

pool_name="github-actions"

echo "➡️ Testing existence of agent ${agent} in pool ${pool_name}"

# Get the pool id
pool_id=$(az pipelines pool list \
  --pool-name "${pool_name}" \
  --query "[0].id")

# Fail if the pool does not exist
if [ -z "$pool_id" ]; then
  echo "❌ Pool ${pool_name} not found"
  exit 1
fi

# Wait for the agent to be created
while true; do
  agent_json=$(az pipelines agent list \
    --pool-id "${pool_id}" \
      | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"${agent}\")) and (.name | endswith(\"-template\")) and .status == \"online\"))")
  if [ -n "$agent_json" ] && [ "$agent_json" != "null" ]; then
    break
  fi
  echo "Template agent ${agent} not found in pool ${pool_name}, retrying in 5 seconds"
  sleep 5
done

# Get the agent id and capabilities
agent_name=$(echo "${agent_json}" | jq -r ".name")
agent_id=$(echo "${agent_json}" | jq -r ".id")
agent_capabilities=$(az pipelines agent show \
  --agent-id "${agent_id}" \
  --include-capabilities \
  --pool-id "${pool_id}" \
    | jq -r ".systemCapabilities")

echo "Capabilities:"
echo ${agent_capabilities} | jq -r "to_entries | map(\"\(.key)=\(.value | tostring)\") | sort[]"

echo "✅ Agent ${agent_name} found in pool ${pool_name}"

echo "➡️ Testing automatic removal of agent ${agent_name} in pool ${pool_name}"

# Wait for the agent to be offline
while true; do
  agent_status=$(az pipelines agent show \
    --agent-id "${agent_id}" \
    --pool-id "${pool_id}" \
      | jq -r ".status")
  if [ "$agent_status" == "offline" ]; then
    break
  fi
  echo "Template agent ${agent} still online, retrying in 5 seconds"
  sleep 5
done

echo "✅ Agent ${agent_name} properly initialized then stopped from pool ${pool_name}"
