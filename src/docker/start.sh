#!/bin/bash
set -e

if [ -z "$AZP_URL" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "$AZP_TOKEN_FILE" ]; then
  if [ -z "$AZP_TOKEN" ]; then
    echo 1>&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  AZP_TOKEN_FILE=/azp/.token
  echo -n $AZP_TOKEN >"$AZP_TOKEN_FILE"
fi

unset AZP_TOKEN

if [ -n "$AZP_WORK" ]; then
  mkdir -p "$AZP_WORK"
fi

print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

print_header "Configuring agent..."

# Allow the agent to run as root (only feasible because the agent is running in a not-reused container)
export AGENT_ALLOW_RUNASROOT="1"
# Let the agent ignore the token env variables
export VSO_AGENT_IGNORE=AZP_TOKEN,AZP_TOKEN_FILE

bash config.sh \
  --acceptTeeEula \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --auth PAT \
  --pool "${AZP_POOL:-Default}" \
  --replace \
  --token $(cat "$AZP_TOKEN_FILE") \
  --unattended \
  --url "$AZP_URL" \
  --work "${AZP_WORK:-_work}" &

# Fake the exit code of the agent for the prevent Kubernetes to detect the pod as failed (this is intended)
# See: https://stackoverflow.com/a/62183992/12732154
wait $!

print_header "Running agent..."

# Running it with the --once flag at the end will shut down the agent after the build is executed
bash run-docker.sh "$@" --once &

# Fake the exit code of the agent for the prevent Kubernetes to detect the pod as failed (this is intended)
# See: https://stackoverflow.com/a/62183992/12732154
wait $!
