#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

: "${THEOS:=$HOME/theos}"
export THEOS

sh "$ROOT_DIR/scripts/fetch-wilhelm-scream.sh"
make clean package
sh "$ROOT_DIR/scripts/patch-package-with-allemande.sh"
