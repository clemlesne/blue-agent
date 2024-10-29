#!/bin/bash
set -e

agent="$1"
pool_id="$2"

if [ -z "$agent" ] || [ -z "$pool_id" ]; then
  echo "Test the existence of a Azure DevOps template agent in a pool."
  echo "Usage: $1 <agent> $2 <pool_id>"
  exit 1
fi

echo "➡️ Testing existence of template agent $agent in pool $pool_id"

# Wait for the agent to start
echo "⏳ Waiting for the agent to start"
while true; do
  agent_json=$(az pipelines agent list \
    --pool-id "$pool_id" \
      | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"$agent\")) and (.name | endswith(\"-template\")) and .status == \"online\")) // empty")
  if [ -n "$agent_json" ]; then
    break
  fi
  echo "Not found, retrying in 5 seconds"
  sleep 5
done

# Get the agent id
agent_name=$(echo "$agent_json" | jq -r ".name")
agent_id=$(echo "$agent_json" | jq -r ".id")
echo "Agent id: $agent_id"

# Get the agent capabilities
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
echo "⏳ Waiting for the agent to be offline"
while true; do
  agent_status=$(az pipelines agent show \
    --agent-id "$agent_id" \
    --pool-id "$pool_id" \
      | jq -r ".status")
  if [ "$agent_status" == "offline" ]; then
    break
  fi
  echo "Still online, retrying in 5 seconds"
  sleep 5
done

echo "✅ Agent properly stopped"
