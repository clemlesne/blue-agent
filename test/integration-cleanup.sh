#!/bin/bash
set -e

agent="$1"

if [ -z "$agent" ]; then
  echo "Clean up integration tests."
  echo "Usage: $1 <agent>"
  exit 1
fi

echo "➡️ Running integration clean up for agent ${agent}"

bash test/azure-devops/template-clean.sh "${agent}"
