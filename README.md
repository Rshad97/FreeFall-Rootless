# FreeFall Rootless

An open-source rootless port of the classic **FreeFall** jailbreak tweak for modern Dopamine/ElleKit environments. The tweak monitors accelerometer data and plays a configurable WAV sound when a free-fall event is detected.

## Status

- Version: **3.0.1**
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
- Replaceable WAV sound at:

  `/var/jb/Library/FreeFallRootless/FreeFallScream.wav`

## Project layout

- `Tweak.xm` — CoreMotion detection and sound playback logic
- `FreeFallRootless.plist` — SpringBoard injection filter
- `Makefile` — Theos tweak build configuration
- `control` — Debian package metadata
- `layout/` — Rootless package resources and PreferenceLoader entry
- `freefallprefs/` — Settings bundle
- `.github/workflows/build.yml` — macOS GitHub Actions build
- `scripts/` — optional on-device build/ABI conversion helpers

## Recommended build: macOS / GitHub Actions

The cleanest way to build modern arm64e SpringBoard tweaks is with current Xcode/macOS.

With Theos installed:

```sh
export THEOS="$HOME/theos"
make clean package FINALPACKAGE=1
```

The resulting package is written to `packages/`.

The repository also includes a GitHub Actions workflow. Push the project to GitHub and run **Build Rootless DEB** from Actions.

## On-device build (Dopamine / NewTerm)

On-device compilation can produce the older arm64e ABI. If that happens, use **Allemande** to convert the final Mach-O files before installing the package.

See:

`docs/ON_DEVICE_BUILD.md`

The helper script `scripts/build-on-device.sh` automates the build plus ABI patching when Allemande is installed.

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

The default sound is the classic **Wilhelm Scream**. The audio is intentionally not vendored in the source archive; the documented build flows fetch the CC0 WAV from the USC/Sunset Editorial collection on Internet Archive before packaging. The installed sound is placed at:

```text
/var/jb/Library/FreeFallRootless/FreeFallScream.wav
```

For a manual build, fetch the default audio first:

```sh
./scripts/fetch-wilhelm-scream.sh
make clean package FINALPACKAGE=1
```

The on-device helper and GitHub Actions workflow do this automatically. See `AUDIO_LICENSE.md` for the CC0 source and licensing details.

## Credits

- Original FreeFall concept/tweak: **Steven Rolfe**
- alexPNG FreeFall fork used as the historical source base
- Rootless/Dopamine port: **Rashad**

## License

GPL-3.0. See `LICENSE`.
