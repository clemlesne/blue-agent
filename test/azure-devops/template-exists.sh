#!/bin/bash
set -e

agent="$1"
pool_id="$2"

if [ -z "$agent" ] || [ -z "$pool_id" ]; then
  echo "Test the existence of a Azure DevOps template agent in a pool."
  echo "Usage: $1 <agent> $2 <pool_id>"
  exit 1
fi

echo "➡️ Testing existence of agent $agent in pool $pool_id"

# Wait for the agent to start
while true; do
  agent_json=$(az pipelines agent list \
    --pool-id "$pool_id" \
      | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"$agent\")) and (.name | endswith(\"-template\")) and .status == \"online\")) // empty")
  if [ -n "$agent_json" ]; then
    break
  fi
  echo "Template agent not found, retrying in 5 seconds"
  sleep 5
done

# Get the agent id and capabilities
agent_name=$(echo "$agent_json" | jq -r ".name")
agent_id=$(echo "$agent_json" | jq -r ".id")
agent_capabilities=$(az pipelines agent show \
  --agent-id "$agent_id" \
  --include-capabilities \
  --pool-id "$pool_id" \
    | jq -r ".systemCapabilities")

echo "Capabilities:"
echo $agent_capabilities | jq -r "to_entries | map(\"\(.key)=\(.value | tostring)\") | sort[]"

echo "✅ Template agent found"

echo "➡️ Testing automatic removal"

# Wait for the agent to be offline
while true; do
  agent_status=$(az pipelines agent show \
    --agent-id "$agent_id" \
    --pool-id "$pool_id" \
      | jq -r ".status")
  if [ "$agent_status" == "offline" ]; then
    break
  fi
  echo "Template agent $agent still online, retrying in 5 seconds"
  sleep 5
done

echo "✅ Agent properly stopped"
