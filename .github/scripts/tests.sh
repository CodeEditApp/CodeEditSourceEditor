#!/bin/bash

ARCH=""

if [ "$1" = "arm" ]; then
    ARCH="arm64"
else
    ARCH="x86_64"
fi

echo "Building with arch: ${ARCH}"

export LC_CTYPE=en_US.UTF-8

DEVICE_ID=$(xcrun xctrace list devices 2>/dev/null | grep -m1 "My Mac" | grep "${ARCH}" | awk -F '[()]' '{print $2}')

if [ -z "$DEVICE_ID" ]; then
  echo "Failed to find device ID for arch ${ARCH}"
  exit 1
fi

echo "Using device ID: $DEVICE_ID"

set -o pipefail && arch -"${ARCH}" xcodebuild  \
           -scheme CodeEditSourceEditor \
           -derivedDataPath ".build" \
           -destination "id=${DEVICE_ID}" \
           -skipPackagePluginValidation \
           clean test | xcpretty
