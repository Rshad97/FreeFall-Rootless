# On-device build with NewTerm

This path is intended for a Dopamine rootless device with Theos installed under `$HOME/theos`.

## Requirements

- Theos
- patched iOS SDK (for example iPhoneOS16.5.sdk)
- `make`, `clang`, `ldid`, `dpkg`, `lipo`, `otool`
- Allemande available in `PATH`

## Build

```sh
cd ~/FreeFall-Rootless
export THEOS="$HOME/theos"
make clean package
```

If the build reports an old/incompatible arm64e ABI, do not install the package yet. Run:

```sh
sh ./scripts/patch-package-with-allemande.sh
```

Or run the combined helper:

```sh
sh ./scripts/build-on-device.sh
```

The patched package is written into `packages/` with `-PATCHED.deb` in its filename.

## Install

```sh
sudo dpkg -i packages/*PATCHED.deb
sudo sbreload
```

## Recovery

If SpringBoard becomes unstable, disable tweak injection from Dopamine or enter a safe environment, then remove the package:

```sh
sudo dpkg -r com.rashad.freefallrootless
sudo sbreload
```
