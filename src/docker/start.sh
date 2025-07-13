#!/bin/bash
set -e

# Start the Azure DevOps agent in a Linux container
#
# Agent is always registered. It is removed from the server only when the agent is not a template job. After 60 secs, it tries to shut down the agent gracefully, waiting for the current job to finish, if any.
#
# TEMPLATE CONTAINER MECHANISM:
# When autoscaling is enabled (KEDA), a first "template" container is created (AZP_TEMPLATE_JOB=1) that:
# - Registers with Azure DevOps for 1 minute to establish pool connection
# - Allows KEDA to monitor the pool for pending jobs and trigger scaling
# - Serves as a "parent" agent that KEDA references for scaling decisions
# - This template container will show "no deploy tasks available" - this is expected behavior
# - Without this template container, KEDA cannot monitor the Azure DevOps pool for autoscaling
#
# Environment variables:
# - AZP_AGENT_NAME: Agent name (default: hostname)
# - AZP_CUSTOM_CERT_PEM: Custom SSL certificates directory (default: empty)
# - AZP_POOL: Agent pool name
# - AZP_TEMPLATE_JOB: Template job flag (default: 0, set to 1 for template containers)
# - AZP_TOKEN: Personal access token
# - AZP_URL: Server URL
# - AZP_WORK: Work directory

##
# Misc functions
##

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

##
# Argument parsing
##

if [ -z "$AZP_URL" ]; then
  raise_error "Missing AZP_URL environment variable"
  exit 1
fi

if [ -z "$AZP_TOKEN" ]; then
  raise_error "Missing AZP_TOKEN environment variable"
  exit 1
fi

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
  write_header "Template Container: This container serves as a 'parent' agent for KEDA autoscaling"
  echo "PURPOSE: The template container registers with Azure DevOps to establish pool connection"
  echo "SCALING: KEDA monitors this template agent to determine when to scale up/down based on job queue"
  echo "BEHAVIOR: This template agent will run for 1 minute and then terminate - this is expected"
  echo "IMPORTANCE: Without this template container, KEDA cannot monitor the Azure DevOps pool for autoscaling"
  is_template_job="true"
  AZP_AGENT_NAME="${AZP_AGENT_NAME}-template"
fi

write_header "Running agent $AZP_AGENT_NAME in pool $AZP_POOL"

##
# Cleanup function
##

unregister() {
  write_header "Removing agent"

  # If the agent has some running jobs, the configuration removal process will fail ; so, give it some time to finish the job
  while true; do
    # If the agent is removed successfully, exit the loop
    /tmp/config.sh remove \
        --auth PAT \
        --token "$AZP_TOKEN" \
        --unattended \
      && break

    echo "A job is still running, waiting 15 seconds before retrying the removal"
    sleep 15
  done
}

##
# Custom SSL certificates
##

write_header "Adding custom SSL certificates"

if [ -d "$AZP_CUSTOM_CERT_PEM" ] && [ "$(ls -A $AZP_CUSTOM_CERT_PEM)" ]; then
  echo "Searching for *.crt in $AZP_CUSTOM_CERT_PEM"

  # Debian-based systems
  if [ -s /etc/debian_version ]; then
    cert_path="/usr/local/share/ca-certificates"
    mkdir -p $cert_path

    # Copy certificates to the certificate path
    cp $AZP_CUSTOM_CERT_PEM/*.crt $cert_path

    # Display certificates information
    for cert_file in $AZP_CUSTOM_CERT_PEM/*.crt; do
      echo "Certificate $(basename $cert_file)"
      openssl x509 -inform PEM -in $cert_file -noout -issuer -subject -dates
    done

    echo "Updating certificates keychain"
    update-ca-certificates
  fi

  # RHEL-based systems
  if [ -s /etc/redhat-release ]; then
    cert_path="/etc/ca-certificates/trust-source/anchors"
    mkdir -p $cert_path

    # Copy certificates to the certificate path
    cp $AZP_CUSTOM_CERT_PEM/*.crt $cert_path

    # Display certificates information
    for cert_file in $AZP_CUSTOM_CERT_PEM/*.crt; do
      echo "Certificate $(basename $cert_file)"
      openssl x509 -inform PEM -in $cert_file -noout -issuer -subject -dates
    done

    echo "Updating certificates keychain"
    update-ca-trust extract
  fi
else
  echo "No custom SSL certificate provided"
fi

##
# Agent configuration
##

write_header "Configuring agent"

cd $(dirname "$0")

/tmp/config.sh \
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

##
# Agent execution
##

write_header "Running agent"

# Running it with the --once flag at the end will shut down the agent after the build is executed
if [ "$is_template_job" == "true" ]; then
  write_header "Starting template agent (1-minute lifecycle for KEDA autoscaling setup)"
  echo "This template agent will:"
  echo "  • Register with Azure DevOps pool to establish connection"
  echo "  • Allow KEDA to monitor the pool for pending jobs"
  echo "  • Automatically terminate after 1 minute (this is expected behavior)"
  echo "  • Enable autoscaling of actual job-running agents based on queue demand"
  echo "Agent will be stopped after 1 min"
  # Run the agent for a minute
  timeout --preserve-status 1m /tmp/run-docker.sh "$@" --once &
else
  write_header "Starting regular agent (will process actual jobs)"
  # Unregister on success
  trap 'unregister; exit 0' EXIT
  # Unregister on Ctrl+C
  trap 'unregister; exit 130' INT
  # Unregister on SIGTERM
  trap 'unregister; exit 143' TERM
  # Run the countdown for fast-clean if no job is using the agent after a delay
  sleep 60 && unregister &
  # Run the agent
  /tmp/run-docker.sh "$@" --once &
fi

# Fake the exit code of the agent for the prevent Kubernetes to detect the pod as failed (this is intended)
# See: https://stackoverflow.com/a/62183992/12732154
wait $!

##
# Diagnostics
##

write_header "Printing agent diag logs"

cat $AGENT_DIAGLOGPATH/*.log
