#!/bin/bash
set -e

agent="$1"
pool_name="$2"

if [ -z "$agent" ] || [ -z "$pool_name" ]; then
  echo "Clean up integration tests."
  echo "Usage: $1 <agent> $2 <pool_name>"
  exit 1
fi

echo "➡️ Running integration clean up for agent ${agent}"

# Get the pool id
pool_id=$(az pipelines pool list \
  --pool-name "${pool_name}" \
  --query "[0].id")

# Fail if the pool does not exist
if [ -z "$pool_id" ]; then
  echo "❌ Pool ${pool_name} not found"
  exit 1
fi

# Manually clean up the template agent
# In a standard deployment, the agent would stay offline indefinitely
bash test/azure-devops/template-clean.sh "${agent}" "${pool_id}"

echo "✅ All clean up done"
