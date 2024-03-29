###
# Test the existence of an Azure DevOps agent in a pool, then run a pipeline and confirm it was successful.
#
# Usage: ./integration.sh <instance> <flavor>
###

#!/bin/bash
set -e

instance="$1"
flavor="$2"

if [ -z "$instance" ] || [ -z "$flavor" ]; then
  echo "Usage: $1 <instance> $2 <flavor>"
  exit 1
fi

org_url="https://dev.azure.com/azure-pipelines-agent"

echo "Configuring Azure DevOps organization ${org_url}"
az devops configure --defaults organization=${org_url}

bash test/azure-devops/exists.sh "apa-${instance}-${flavor}"

for test in $(basename -s .yaml test/pipeline/*.yaml)
do
  bash test/azure-devops/pipeline.sh ${instance} ${test} ${flavor} &
done

# Wait for all background jobs to complete and exit if any of them fail
wait
if [ $? -ne 0 ]; then
  echo "A test failed. Exiting..."
  kill $(jobs -p) 2>/dev/null
  exit 1
fi
