#!/bin/bash
set -e

if [ -z "$AZP_URL" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "$AZP_TOKEN" ]; then
  echo 1>&2 "error: missing AZP_TOKEN environment variable"
  exit 1
fi

if [ -z "$AZP_POOL" ]; then
  echo 1>&2 "error: missing AZP_POOL environment variable"
  exit 1
fi

if [ -z "$AZP_AGENT_NAME" ]; then
  echo 1>&2 "error: missing AZP_AGENT_NAME environment variable"
  exit 1
fi

if [ -z "$AZP_AGENT_NAME" ]; then
  echo 1>&2 "error: missing AZP_AGENT_NAME environment variable"
  exit 1
fi

if [ ! -w "$AZP_WORK" ]; then
  echo 1>&2 "error: work dir AZP_WORK (${AZP_WORK}) is not writeable or does not exist"
  exit 1
fi

print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}➡️ $1${nocolor}"
}

export AGENT_ALLOW_RUNASROOT=1

cd $(dirname "$0")

print_header "Configuring agent..."

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

print_header "Running agent..."

# Running it with the --once flag at the end will shut down the agent after the build is executed
bash run-docker.sh "$@" --once &

# Fake the exit code of the agent for the prevent Kubernetes to detect the pod as failed (this is intended)
# See: https://stackoverflow.com/a/62183992/12732154
wait $!
