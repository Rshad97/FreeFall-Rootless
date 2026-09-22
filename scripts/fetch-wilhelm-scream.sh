#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
URL='https://archive.org/download/SSE_Library_VOICES/SCREAM/VOXScrm_Man%20eaten%20by%20alligator%3B%20screams%20%5BWilhelm_CS_USC.wav'
TMP="${TMPDIR:-/tmp}/FreeFall-WilhelmScream.wav"

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required to fetch the CC0 Wilhelm Scream" >&2
  exit 1
fi

printf '%s\n' 'Fetching CC0 Wilhelm Scream from Internet Archive…'
curl -fL --retry 3 --retry-delay 1 "$URL" -o "$TMP"

mkdir -p "$ROOT_DIR/Resources" "$ROOT_DIR/layout/Library/FreeFallRootless"
cp "$TMP" "$ROOT_DIR/Resources/FreeFallScream.wav"
cp "$TMP" "$ROOT_DIR/layout/Library/FreeFallRootless/FreeFallScream.wav"

printf '%s\n' "Updated: $ROOT_DIR/Resources/FreeFallScream.wav"
printf '%s\n' "Updated: $ROOT_DIR/layout/Library/FreeFallRootless/FreeFallScream.wav"
printf '%s\n' 'Source: USC/Sunset Editorial sound-effects collection via Internet Archive (CC0 1.0).'
