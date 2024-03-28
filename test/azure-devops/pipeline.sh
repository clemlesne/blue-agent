###
# Run a local pipeline file in Azure DevOps, setup the environment, wait for completion and return the result.
#
# Usage: ./pipeline.sh <prefix> <pipeline> <flavor>
###

#!/bin/bash
set -e

prefix="$1"
pipeline="$2"
flavor="$3"

if [ -z "$prefix" ] || [ -z "$pipeline" ] || [ -z "$flavor" ]; then
  echo "Usage: $1 <prefix> $2 <pipeline> $3 <flavor>"
  exit 1
fi

pipeline_path="test/pipeline/${pipeline}.yaml"
if [ ! -f "${PWD}/${pipeline_path}" ]; then
  echo "Pipeline ${pipeline_path} does not exist"
  echo "Available pipelines:"
  ls -1 "${PWD}/test/pipeline/*.yaml" | sed 's/\.yaml$//'
  exit 1
fi

organization_url=$(az devops configure --list | grep 'organization =' | cut -d'=' -f2 | tr -d '[:space:]')
pool_name="github-actions"
project_name="${prefix}-${flavor}"
service_connection_name="${project_name}"
pipeline_name="${pipeline}"

echo "➡️ Creating project ${project_name} in organization ${organization_url}"
if az devops project show --project ${project_name} \
      &> /dev/null; then
  echo "Project ${project_name} already exists"
else
  az devops project create \
    --description "Integration test for image `${flavor}`. Related to the project [azure-pipelines-agent](https://github.com/clemlesne/azure-pipelines-agent)." \
    --name ${project_name} \
    --visibility public
fi
project_id=$(az devops project show --project ${project_name} \
  | jq -r '.id')
flock $HOME/.azure/azuredevops/config --command "az devops configure --defaults project=${project_id}"

echo "➡️ Getting agent pool ${pool_name}"
queue_id=$(az pipelines queue list \
  --query "[?name=='${pool_name}'].id" \
    | jq -r '.[0]')
if [ -z "${queue_id}" ]; then
  echo "Agent pool ${pool_name} does not exist"
  exit 1
fi

echo "➡️ Creating service connection ${service_connection_name}"
if az devops service-endpoint show \
    --id $(az devops service-endpoint list \
      --query "[?name=='${service_connection_name}']" \
        | jq -r '.[0].id') \
          &> /dev/null; then
  echo "Service connection ${service_connection_name} already exists"
else
  az devops service-endpoint github create \
    --name ${service_connection_name} \
    --github-url $(git remote get-url origin)
fi
service_connection_id=$(az devops service-endpoint list --query "[?name=='${service_connection_name}']" \
    | jq -r '.[0].id')

echo "➡️ Creating pipeline ${pipeline_name} in project ${project_name}"
if az pipelines show --name "${pipeline_name}" \
      &> /dev/null; then
  echo "Pipeline ${pipeline_name} already exists"
else
  az pipelines create \
    --branch $(git rev-parse --abbrev-ref HEAD) \
    --description "Test pipeline `${pipeline}`. Created from GitHub Actions." \
    --name ${pipeline_name} \
    --repository $(git remote get-url origin) \
    --repository-type github \
    --service-connection ${service_connection_id} \
    --skip-first-run \
    --yml-path ${pipeline_path}
fi
pipeline_id=$(az pipelines show --name "${pipeline_name}" \
  | jq -r '.id')

echo "➡️ Authorizing pipeline ${pipeline_name} to run on agent pool ${pool_name}"
# TODO: Use Azure CLI to auhorize the pipeline to run on the agent pool (see: https://github.com/Azure/azure-cli/issues/28111)
tmp_file=$(mktemp -t XXXXXX.json)
cat <<EOF > ${tmp_file}
{
  "pipelines": [{
    "authorized": true,
    "id": "${pipeline_id}"
  }]
}
EOF
az devops invoke \
  --api-version 7.1-preview \
  --area pipelinePermissions \
  --http-method PATCH \
  --in-file ${tmp_file} \
  --resource pipelinePermissions \
  --route-parameters project=${project_id} resourceType=queue resourceId=${queue_id} \
    > /dev/null
rm -f ${tmp_file}

echo "➡️ Running pipeline ${pipeline_name}"
run_json=$(az pipelines run \
  --commit-id $(git rev-parse HEAD) \
  --id "${pipeline_id}" \
  --parameters flavor=${flavor})
run_id=$(echo ${run_json} | jq -r '.id')

echo "➡️ Waiting for pipeline run ${run_id} to complete"
echo "🔗 ${organization_url}/${project_name}/_build/results?buildId=${run_id}"

timeout_seconds=900 # 15 minutes
start_time=$(date +%s)
while true; do
  run_json=$(az pipelines runs show --id ${run_id})
  status=$(echo ${run_json} | jq -r '.status')

  if [ "${status}" == "completed" ]; then
    result=$(echo ${run_json} | jq -r '.result')
    validation_results=$(echo ${run_json} | jq -r '.validationResults')
    echo "Validation results:"
    echo ${validation_results} | jq

    if [ "${result}" == "succeeded" ]; then
      echo "✅ Pipeline run ${run_id} succeeded"
      exit 0
    else
      echo "❌ Pipeline run ${run_id} failed"
      exit 1
    fi
  fi

  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
  if [ ${elapsed_time} -ge ${timeout_seconds} ]; then
    echo "⏰ Timeout reached, pipeline run ${run_id} did not complete within ${timeout_seconds} seconds"

    echo "➡️ Cancelling pipeline run ${run_id}"
    # TODO: Use Azure CLI to auhorize the pipeline to run on the agent pool (see: https://github.com/Azure/azure-devops-cli-extension/issues/876)
    tmp_file=$(mktemp -t XXXXXX.json)
    cat <<EOF > ${tmp_file}
{
  "status": "cancelling"
}
EOF
    az devops invoke \
      --api-version 7.1-preview \
      --area build \
      --http-method PATCH \
      --in-file ${tmp_file} \
      --resource builds \
      --route-parameters project=${project_id} buildId=${run_id} \
        > /dev/null

    exit 1
  fi

  echo "Pipeline run ${run_id} is ${status}, retrying in 5 seconds"
  sleep 5
done
