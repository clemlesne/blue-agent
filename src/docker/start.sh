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

if [ -z "$AZP_POOL" ]; then
  raise_error "Missing AZP_POOL environment variable"
  exit 1
fi

# If AZP_AGENT_NAME is not set, use the container hostname
if [ -z "$AZP_AGENT_NAME" ]; then
  write_warning "Missing AZP_AGENT_NAME environment variable"
  AZP_AGENT_NAME=$(hostname)
fi

if [ -z "$AZP_AGENT_NAME" ]; then
  raise_error "Missing AZP_AGENT_NAME environment variable"
  exit 1
fi

if [ ! -w "$AZP_WORK" ]; then
  raise_error "Work dir AZP_WORK (${AZP_WORK}) is not writeable or does not exist"
  exit 1
fi

write_header "Running agent $AZP_AGENT_NAME in pool $AZP_POOL"

unregister() {
  write_header "Removing agent"

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

write_header "Adding custom SSL certificates"
if [ -d "$AZP_CUSTOM_CERT_PEM" ] && [ "$(ls -A $AZP_CUSTOM_CERT_PEM)" ]; then
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
else
  echo "No custom SSL certificate provided"
fi

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

# Unregister on success
trap 'unregister; exit 0' EXIT
# Unregister on Ctrl+C
trap 'unregister; exit 130' INT
# Unregister on SIGTERM
trap 'unregister; exit 143' TERM

write_header "Running agent"

# Running it with the --once flag at the end will shut down the agent after the build is executed
bash run-docker.sh "$@" --once &

# Fake the exit code of the agent for the prevent Kubernetes to detect the pod as failed (this is intended)
# See: https://stackoverflow.com/a/62183992/12732154
wait $!

write_header "Printing agent diag logs"

cat $AGENT_DIAGLOGPATH/*.log
