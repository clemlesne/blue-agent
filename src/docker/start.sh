#!/bin/bash
set -e

write_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}➡️ $1${nocolor}"
}

write_warning() {
  yellow='\033[1;33m'
  nocolor='\033[0m'
  echo -e "${yellow}⚠️ $1${nocolor}"
}

raise_error() {
  red='\033[1;31m'
  nocolor='\033[0m'
  echo 1>&2 -e "${red}❌ $1${nocolor}"
}

if [ -z "$AZP_URL" ]; then
  raise_error "Missing AZP_URL environment variable"
  exit 1
fi

if [ -z "$AZP_TOKEN" ]; then
  raise_error "Missing AZP_TOKEN environment variable"
  exit 1
fi
# Configure the Azure DevOps CLI to use the provided token
export AZURE_DEVOPS_EXT_PAT="$AZP_TOKEN"

if [ -z "$AZP_POOL" ]; then
  raise_error "Missing AZP_POOL environment variable"
  exit 1
fi

# If name is not set, use the hostname
if [ -z "$AZP_AGENT_NAME" ]; then
  write_warning "Missing AZP_AGENT_NAME environment variable, using hostname"
  AZP_AGENT_NAME=$(hostname)
fi

if [ ! -w "$AZP_WORK" ]; then
  write_warning "Work dir AZP_WORK (${AZP_WORK}) does not exist, creating it, but reliability is not guaranteed"
  mkdir -p "$AZP_WORK"
fi

if [ "$AZP_TEMPLATE_JOB" == "1" ]; then
  write_warning "Template job enabled, agent cannot be used for running jobs"
  isTemplateJob="true"
  AZP_AGENT_NAME="${AZP_AGENT_NAME}-template"
fi

unregister_now() {
  write_header "Removing agent"

  # A job with the deployed configuration need to be kept in the server history, so a pipeline can be run and KEDA detect it from the queue
  if [ "$isTemplateJob" == "true" ]; then
    echo "Ignoring cleanup"
    return
  fi

  # If the agent has some running jobs, the configuration removal process will fail ; so, give it some time to finish the job
  while true; do
    # If the agent is removed successfully, exit the loop
    bash config.sh remove \
        --auth PAT \
        --token "$AZP_TOKEN" \
        --unattended \
      && break

    echo "Retrying in 15 secs"
    sleep 15
  done
}

unregister_if_not_used() {
  write_header "Checking if agent can be removed"

  # Get pool id
  pool_id=$(az pipelines pool list \
    --pool-name "$AZP_POOL" \
    --query "[0].id")
  # Get agent requests
  agent=$(az pipelines agent list \
    --include-assigned-request \
    --include-last-completed-request \
    --pool-id "$pool_id" \
    --query "[?agent.name=='$AZP_AGENT_NAME'] | [0]")
  assignedRequest=$(echo $agent | jq -r '.assignedRequest // empty')
  lastCompletedRequest=$(echo $agent | jq -r '.lastCompletedRequest // empty')

  # If the agent has requests, abort
  if [ ! -z "$assignedRequest" ] || [ ! -z "$lastCompletedRequest" ]; then
    echo "Agent has requests, cannot be removed"
    return
  fi

  # Remove the agent
  echo "Agent has no requests, removing it"
  unregister_now
}

add_custom_ssl_certificates() {
  write_header "Adding custom SSL certificates"

  if [ ! -d "$AZP_CUSTOM_CERT_PEM" ] || [ -z "$(ls -A $AZP_CUSTOM_CERT_PEM)" ]; then
    echo "No custom SSL certificate provided"
    return
  fi

  echo "Searching for *.crt in $AZP_CUSTOM_CERT_PEM"

  # Debian-based systems
  if [ -s /etc/debian_version ]; then
    certPath="/usr/local/share/ca-certificates"
    mkdir -p $certPath

    # Copy certificates to the certificate path
    cp $AZP_CUSTOM_CERT_PEM/*.crt $certPath

    # Display certificates information
    for certFile in $AZP_CUSTOM_CERT_PEM/*.crt; do
      echo "Certificate $(basename $certFile)"
      openssl x509 -inform PEM -in $certFile -noout -issuer -subject -dates
    done

    echo "Updating certificates keychain"
    update-ca-certificates
  fi

  # RHEL-based systems
  if [ -s /etc/redhat-release ]; then
    certPath="/etc/ca-certificates/trust-source/anchors"
    mkdir -p $certPath

    # Copy certificates to the certificate path
    cp $AZP_CUSTOM_CERT_PEM/*.crt $certPath

    # Display certificates information
    for certFile in $AZP_CUSTOM_CERT_PEM/*.crt; do
      echo "Certificate $(basename $certFile)"
      openssl x509 -inform PEM -in $certFile -noout -issuer -subject -dates
    done

    echo "Updating certificates keychain"
    update-ca-trust extract
  fi
}

configure_agent() {
  write_header "Configuring agent"

  cd $(dirname "$0")

  bash config.sh \
    --acceptTeeEula \
    --agent "$AZP_AGENT_NAME" \
    --auth PAT \
    --pool "$AZP_POOL" \
    --replace \
    --token "$AZP_TOKEN" \
    --unattended \
    --url "$AZP_URL" \
    --work "$AZP_WORK" &

  # Fake the exit code of the agent for the prevent Kubernetes to detect the pod as failed (this is intended)
  # See: https://stackoverflow.com/a/62183992/12732154
  wait $!
}

run_agent() {
  write_header "Running agent $AZP_AGENT_NAME in pool $AZP_POOL"

  # Running it with the --once flag at the end will shut down the agent after the build is executed
  if [ "$isTemplateJob" == "true" ]; then
    echo "Agent will be stopped after 1 min"
    # Run the agent for a minute
    timeout --preserve-status 1m bash run-docker.sh "$@" --once &
  else
    # Run the countdown
    sleep 60 && unregister_if_not_used &
    # Run the agent
    bash run-docker.sh "$@" --once &
  fi

  # Fake the exit code of the agent for the prevent Kubernetes to detect the pod as failed (this is intended)
  # See: https://stackoverflow.com/a/62183992/12732154
  wait $!

  write_header "Printing agent diag logs"

  cat $AGENT_DIAGLOGPATH/*.log
}

write_header "Configuring Azure CLI"
az devops configure --defaults organization=$AZP_URL

add_custom_ssl_certificates

configure_agent

# Unregister on success
trap 'unregister_now; exit 0' EXIT
# Unregister on Ctrl+C
trap 'unregister_now; exit 130' INT
# Unregister on SIGTERM
trap 'unregister_now; exit 143' TERM

run_agent
