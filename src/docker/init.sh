#!/bin/bash
set -e

AGENT_VERSION=$1
SYS_ARCH="$(arch)"

if [ -z "$AGENT_VERSION" ]; then
  echo 1>&2 "error: missing AGENT_VERSION argument"
  exit 1
fi

echo "Install v$AGENT_VERSION for $SYS_ARCH requested..."

AGENT_ARCH=$SYS_ARCH
if [[ $AGENT_ARCH == x86_64 ]]; then
  AGENT_ARCH="linux-x64"
elif [[ $AGENT_ARCH == arm* ]]; then
  AGENT_ARCH="linux-arm"
elif [[ $AGENT_ARCH == aarch64 ]]; then
  AGENT_ARCH="linux-arm64"
else
  echo 1>&2 "Unsupported architecture"
  exit 1
fi

AGENT_PACKAGE_URL="https://vstsagentpackage.azureedge.net/agent/$AGENT_VERSION/pipelines-agent-$AGENT_ARCH-$AGENT_VERSION.tar.gz"

curl -LsS $AGENT_PACKAGE_URL | tar -xz &
wait $!

echo "Agent v$AGENT_VERSION for $AGENT_ARCH installed"
