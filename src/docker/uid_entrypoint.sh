#!/bin/bash
set -e

if ! whoami &>/dev/null; then
  # Create arbitrary user at run-time
  echo "${USER}:x:$(id -u):0:::${HOME}:/sbin/nologin" >>/etc/passwd
  # Allow to log without password
  echo "${USER}:!:18000:0:99999:7:::" >>/etc/shadow
  # Reset permissions for local user
  sudo chmod a-w /etc/passwd /etc/shadow

  # Local config for BuildKit
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  export BUILDKIT_HOST=unix:///run/user/$(id -u)/buildkit/buildkitd.sock
fi

exec "$@"
