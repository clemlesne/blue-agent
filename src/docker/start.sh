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

if [ -n "$AZP_WORK" ]; then
  mkdir -p "$AZP_WORK"
fi

print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}➡️ $1${nocolor}"
}

print_header "Configuring agent..."

bash config.sh \
  --acceptTeeEula \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --auth PAT \
  --pool "${AZP_POOL:-Default}" \
  --replace \
  --token "$AZP_TOKEN" \
  --unattended \
  --url "$AZP_URL" \
  --work "${AZP_WORK:-_work}"

print_header "Running agent..."

# Running it with the --once flag at the end will shut down the agent after the build is executed
bash run-docker.sh "$@" --once
