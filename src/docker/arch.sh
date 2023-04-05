#!/bin/bash
set -e

ARCH_AMD64="${ARCH_AMD64:-x64}"
ARCH_ARM32="${ARCH_ARM32:-arm}"
ARCH_ARM64="${ARCH_ARM64:-arm64}"

SYS_ARCH="$(arch)"

if [[ $SYS_ARCH == x86_64 ]]; then
  SYS_ARCH=$ARCH_AMD64
elif [[ $SYS_ARCH == aarch64 || $SYS_ARCH == arm64 ]]; then
  SYS_ARCH=$ARCH_ARM64
elif [[ $SYS_ARCH == arm* ]]; then
  SYS_ARCH=$ARCH_ARM32
else
  echo 1>&2 "Unsupported architecture $SYS_ARCH"
  exit 1
fi

echo $SYS_ARCH
