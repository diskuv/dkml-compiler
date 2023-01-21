#!/bin/sh
set -euf

CROSSPLAT=$1
shift
VERSION=$1
shift
FILE=$1
shift

# shellcheck disable=SC1090
. "$CROSSPLAT"

# Set WORK
create_workdir
trap 'PATH=/usr/bin:/bin rm -rf "$WORK"' EXIT

URL="https://github.com/diskuv/dkml-compiler/releases/download/${VERSION}/${FILE}"

# Set DKMLSYS_*
autodetect_system_binaries

# Download
printf "Downloading %s ...\n" "$URL" >&2
log_trace "$DKMLSYS_CURL" -L -s "$URL" -o "$WORK/file"

# Compute checksum
sha256compute "$WORK/file"
printf "  Checksum computed.\n" >&2
