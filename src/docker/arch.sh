#!/bin/bash
set -e

SYS_ARCH="$(arch)"

if [[ $SYS_ARCH == x86_64 ]]; then
  SYS_ARCH="linux-x64"
elif [[ $SYS_ARCH == arm* ]]; then
  SYS_ARCH="linux-arm"
elif [[ $SYS_ARCH == aarch64 ]]; then
  SYS_ARCH="linux-arm64"
else
  echo 1>&2 "Unsupported architecture"
  exit 1
fi

echo $SYS_ARCH
