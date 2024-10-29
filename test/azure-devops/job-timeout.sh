#!/bin/bash
set -e

agent="$1"
pool_id="$2"
rg_name="$3"

if [ -z "$agent" ] || [ -z "$pool_id" ] || [ -z "$rg_name" ]; then
  echo "Test is the agent properly timed out if it has no activity."
  echo "Usage: $1 <agent> $2 <pool_id> $3 <rg_name>"
  exit 1
fi

echo "➡️ Testing timeout of agent $agent in pool $pool_id, from job $agent in resource group $rg_name"

# Trigger the job
echo "Triggering job"
az containerapp job start \
  --name $agent \
  --resource-group $rg_name

# Wait for the agent to start
echo "⏳ Waiting for the agent to start"
while true; do
  agent_id=$(az pipelines agent list \
    --pool-id $pool_id \
    | jq -r "last(sort_by(.createdOn) | .[] | select((.name | startswith(\"$agent\")) and .status == \"online\")).id // empty")
  if [ -n "$agent_id" ]; then
    break
  fi
  echo "Not found, retrying in 5 seconds"
  sleep 5
done

# Default is 1 minute, but we offer some extra time
echo "⏳ Waiting 2 minutes for agent to time out"
sleep 120

# Check the agent is offline
agent_status=$(az pipelines agent show \
  --agent-id $agent_id \
  --pool-id $pool_id \
    | jq -r ".status")
echo "Agent status: $agent_status"

# Fail if the agent is still online
if [ "$agent_status" == "offline" ]; then
  echo "❌ Agent did not time out"
  exit 1
fi

echo "✅ Agent properly timed out"
