#!/bin/sh
set -eu

command -v allemande >/dev/null 2>&1 || { echo "allemande not found in PATH" >&2; exit 1; }
command -v lipo >/dev/null 2>&1 || { echo "lipo not found in PATH" >&2; exit 1; }
command -v ldid >/dev/null 2>&1 || { echo "ldid not found in PATH" >&2; exit 1; }
command -v dpkg-deb >/dev/null 2>&1 || { echo "dpkg-deb not found in PATH" >&2; exit 1; }

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

DEB=$(ls -t packages/*.deb 2>/dev/null | grep -v -- '-PATCHED\.deb$' | head -n 1 || true)
[ -n "$DEB" ] || { echo "No unpatched package found in packages/" >&2; exit 1; }

WORK="$HOME/FreeFall-PATCHED"
ABI="$HOME/FreeFall-ABI"
rm -rf "$WORK" "$ABI"
mkdir -p "$WORK" "$ABI"

dpkg-deb -R "$DEB" "$WORK"

DYLIB="$WORK/var/jb/Library/MobileSubstrate/DynamicLibraries/FreeFallRootless.dylib"
PREF="$WORK/var/jb/Library/PreferenceBundles/FreeFallRootlessPrefs.bundle/FreeFallRootlessPrefs"

[ -f "$DYLIB" ] || { echo "Tweak dylib not found: $DYLIB" >&2; exit 1; }
[ -f "$PREF" ] || { echo "Preference bundle executable not found: $PREF" >&2; exit 1; }

echo "Converting tweak arm64e ABI..."
cp "$DYLIB" "$ABI/FreeFallRootless-old.dylib"
allemande "$ABI/FreeFallRootless-old.dylib" "$ABI/FreeFallRootless-new.dylib"
cp "$ABI/FreeFallRootless-new.dylib" "$DYLIB"
ldid -S "$DYLIB"

echo "Converting arm64e slice of preference bundle..."
lipo "$PREF" -thin arm64 -output "$ABI/Prefs-arm64"
lipo "$PREF" -thin arm64e -output "$ABI/Prefs-arm64e-old"
allemande "$ABI/Prefs-arm64e-old" "$ABI/Prefs-arm64e-new"
lipo -create "$ABI/Prefs-arm64" "$ABI/Prefs-arm64e-new" -output "$ABI/FreeFallRootlessPrefs"
cp "$ABI/FreeFallRootlessPrefs" "$PREF"
ldid -S "$PREF"

BASE=$(basename "$DEB" .deb)
OUT="packages/${BASE}-PATCHED.deb"
rm -f "$OUT"
dpkg-deb -b "$WORK" "$OUT"

echo "Patched package: $OUT"
