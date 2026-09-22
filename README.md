# FreeFall Rootless

An open-source rootless port of the classic **FreeFall** jailbreak tweak for modern Dopamine/ElleKit environments. The tweak monitors accelerometer data and plays a configurable WAV sound when a free-fall event is detected.

## Status

- Version: **3.0.2**
- Package ID: `com.rashad.freefallrootless`
- Rootless package layout (`/var/jb`)
- SpringBoard injection through ElleKit
- PreferenceLoader settings pane
- Live preference reload through Darwin notifications
- Tested successfully on an **A12 iPhone XS Max running Dopamine 3 rootless**

## Features

- Enable/disable switch
- Adjustable free-fall sensitivity
- Adjustable impact/reset threshold
- CoreMotion callback-based monitoring instead of a polling timer
- Cooldown/reset logic to avoid repeated triggers during one fall
- Replaceable WAV sound at `/var/jb/Library/FreeFallRootless/FreeFallScream.wav`

## Project layout

- `Tweak.xm` — CoreMotion detection and sound playback logic
- `FreeFallRootless.plist` — SpringBoard injection filter
- `Makefile` — Theos tweak build configuration
- `control` — Debian package metadata
- `layout/` — Rootless package resources and PreferenceLoader entry
- `freefallprefs/` — Settings bundle
- `.github/workflows/build.yml` — macOS GitHub Actions build
- `scripts/` — on-device build/ABI conversion helpers

## Recommended build: macOS / GitHub Actions

The cleanest way to build modern arm64e SpringBoard tweaks is with current Xcode/macOS.

With Theos installed:

```sh
export THEOS="$HOME/theos"
sh ./scripts/fetch-wilhelm-scream.sh
make clean package FINALPACKAGE=1
```

The resulting package is written to `packages/`.

The repository also includes a GitHub Actions workflow. Run **Build Rootless DEB** from the Actions tab.

## On-device build (Dopamine / NewTerm)

On-device compilation can produce the older arm64e ABI. If that happens, use **Allemande** to convert the final Mach-O files before installing the package.

See `docs/ON_DEVICE_BUILD.md`.

The combined helper is:

```sh
sh ./scripts/build-on-device.sh
```

## Preferences

PreferenceLoader entry:

`/var/jb/Library/PreferenceLoader/Preferences/FreeFallRootless.plist`

Preference bundle:

`/var/jb/Library/PreferenceBundles/FreeFallRootlessPrefs.bundle`

Preferences domain:

`com.rashad.freefallrootless`

Darwin reload notification:

`com.rashad.freefallrootless/ReloadPrefs`

## Sound

The default sound is the classic **Wilhelm Scream**. Build scripts fetch the CC0 1.6-second Wikimedia Commons clip and convert it to a System Sound compatible WAV: mono, 48 kHz, 16-bit linear PCM. This is important because iOS System Sound Services only supports short sounds (30 seconds or less) in linear PCM/IMA4 inside CAF, AIF, or WAV containers.

Installed path:

`/var/jb/Library/FreeFallRootless/FreeFallScream.wav`

See `AUDIO_LICENSE.md` for source and licensing information.

## Credits

- Original FreeFall concept/tweak: **Steven Rolfe**
- alexPNG FreeFall fork used as the historical source base
- Rootless/Dopamine port: **Rashad**

## License

GPL-3.0. See `LICENSE`.
