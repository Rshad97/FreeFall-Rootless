#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
URL='https://commons.wikimedia.org/wiki/Special:Redirect/file/Wilhelm_Scream.ogg'
TMP_OGG="${TMPDIR:-/tmp}/FreeFall-WilhelmScream.ogg"
TMP_WAV="${TMPDIR:-/tmp}/FreeFall-WilhelmScream.wav"

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "error: ffmpeg is required to convert the CC0 Wilhelm clip to a System Sound compatible WAV" >&2
  exit 1
fi

printf '%s\n' 'Fetching the 1.6-second CC0 Wilhelm Scream from Wikimedia Commons…'
curl -fL --retry 3 --retry-delay 1 "$URL" -o "$TMP_OGG"

printf '%s\n' 'Converting to mono 48 kHz 16-bit linear PCM WAV…'
ffmpeg -y -loglevel error -i "$TMP_OGG" -ac 1 -ar 48000 -c:a pcm_s16le "$TMP_WAV"

mkdir -p "$ROOT_DIR/Resources" "$ROOT_DIR/layout/Library/FreeFallRootless"
cp "$TMP_WAV" "$ROOT_DIR/Resources/FreeFallScream.wav"
cp "$TMP_WAV" "$ROOT_DIR/layout/Library/FreeFallRootless/FreeFallScream.wav"

if command -v ffprobe >/dev/null 2>&1; then
  DURATION=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$TMP_WAV" 2>/dev/null || true)
  printf '%s\n' "Prepared Wilhelm WAV duration: ${DURATION:-unknown}s"
fi

printf '%s\n' "Updated: $ROOT_DIR/layout/Library/FreeFallRootless/FreeFallScream.wav"
