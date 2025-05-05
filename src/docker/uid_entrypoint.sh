#!/bin/bash
set -e

uid=$(id -u)
gid=$(id -g)

# If UID isn’t in passwd, add it (Red Hat OpenShift can force it before the entrypoint)
if ! whoami &>/dev/null; then
  # Create arbitrary user at run-time
  echo "${USER}:x:${uid}:${gid}:${USER}:${HOME}:/sbin/nologin" >>/etc/passwd
  # Allow to log without password
  echo "${USER}:!:18000::::::" >>/etc/shadow
fi

# Reset passwd and shadow files permissions
chmod go-w /etc/passwd /etc/shadow

# Local config for BuildKit
export XDG_RUNTIME_DIR=/run/user/${uid}
export BUILDKIT_HOST=unix:///run/user/${uid}/buildkit/buildkitd.sock

# Execute the initial command
exec "$@"
